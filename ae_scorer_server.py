import argparse
from sd_ext.aesthetic import (
    AestheticPredictor,
    AestheticPredictorRelu,
    AestheticPredictorSE,
    AestheticPredictorSwish,
    AestheticScorer,
)
from PIL import Image
from sd_ext.files import load_file
from sd_ext.clip import get_image_features
import open_clip
import torch
import torch.nn.functional as F
from fastapi import FastAPI, UploadFile


def get_model(model_name, embedding_size, adaptive_pool=True):
    if model_name == "AestheticPredictorSwish":
        model = AestheticPredictorSwish
    elif model_name == "AestheticPredictorSE":
        model = AestheticPredictorSE
    elif model_name == "AestheticPredictorRelu":
        model = AestheticPredictorRelu
    else:
        model = AestheticPredictor

    return model(embedding_size, adaptive_pool=adaptive_pool)


device = "cuda" if torch.cuda.is_available() else "cpu"
model_file = "/home/rockerboo/code/sd-ext/training/sets/2023-12-10-223958/AestheticPredictorSE_ava_openai_clip_L14_5_128.safetensors"

print("Loading CLIP ViT-L-14...")

clip_model, _, preprocess = open_clip.create_model_and_transforms(
    "ViT-L-14", pretrained="openai"
)
clip_model.to(device)

model_file = model_file
state, metadata = load_file(model_file)
print(metadata)

print([key for key in state.keys()])

predictor = get_model(
    metadata["ae_model"],
    int(metadata["ae_embedding_size"]),
)
predictor.load_state_dict(state)
predictor.eval()
predictor.to(device)

aesthetic_scorer = AestheticScorer(predictor, clip_model, preprocess, device)

clip_image_embeddings = []

# HTTP Server
app = FastAPI()


@app.get("/")
def read_root():
    return {"Hello": "World"}


@app.post("/aesthetic_score")
@torch.no_grad()
def post_item(file: UploadFile):
    with Image.open(file.file) as image:
        score = aesthetic_scorer.score(image)
    return {"image_file": file.filename, "aesthetic_score": score}


@app.post("/similarity")
@torch.no_grad()
def similarity(file: UploadFile, file2: UploadFile):
    with Image.open(file.file) as image, Image.open(file2.file) as image2:
        image = get_image_features(preprocess, clip_model, image, device)
        image2 = get_image_features(preprocess, clip_model, image2, device)

        similarity = F.cosine_similarity(image, image2)
    return {
        "image_file_1": file.filename,
        "image_file_2": file.filename,
        "similarity": similarity.item(),
    }


@app.post("/calc_similarity")
@torch.no_grad()
def image_to_embedding(file: UploadFile):
    with Image.open(file.file) as image:
        embedding = get_image_features(preprocess, clip_model, image, device)

    clip_image_embeddings.append(embedding)

    return {
        "image_file_2": file.filename,
        "embedding": embedding,
    }


@app.post("/dataset_similarity")
@torch.no_grad()
def dataset_similarity(file: UploadFile):
    with Image.open(file.file) as image:
        image_embedding = get_image_features(
            preprocess, clip_model, image, device
        )

    similarities = []
    for dataset_image_embedding in clip_image_embeddings:
        similarity = F.cosine_similarity(
            dataset_image_embedding, image_embedding
        )
        similarities.append(similarity)

    return {
        "image_file_1": file.filename,
        "similarities": similarities,
    }
