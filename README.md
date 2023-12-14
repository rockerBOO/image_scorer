# image_scorer

<!--toc:start-->

- [image_scorer](#imagescorer)
  - [Experiments](#experiments)
  - [Usage](#usage)
    - [Create images.json](#create-imagesjson)
    - [Web service](#web-service)
    - [Aesthetic prediction and similarity](#aesthetic-prediction-and-similarity)
  - [Tests](#tests)
  - [Contribute](#contribute)
  - [TODO](#todo)
    - [Additional improvements](#additional-improvements)
  - [BUGS](#bugs)
    - [Preference](#preference)
    <!--toc:end-->

Web application for capturing image scores. Different experiments for capturing the image ratings.

## Experiments

- Score an image
- Rate an image
- Preference
- Similarity

![](https://github.com/rockerBOO/image_scorer/assets/15027/ea4a48fe-a6b7-4e73-bc74-8502a4f311c1)

Score an image based on 1 to 10. Skip means give no rating, and back to the last rating to re-rate it.

![Screenshot 2023-12-11 at 15-01-04 Screenshot](https://github.com/rockerBOO/image_scorer/assets/15027/6a6509a4-6e4a-437e-8fb7-dfee8f5387f3)

Get a predicted score, and modify it to the rating you think it should be. `--` down by 1.0, `-` down by 0.1, `+` up by 0.1 `++` up by 1.0.

![Screenshot 2023-12-11 at 16-28-47 Screenshot](https://github.com/rockerBOO/image_scorer/assets/15027/371e5886-8ad7-4384-96a7-943c0b89f05e)

Pick a image you prefer out of the list of 4 images. Alternative of best of 2 images.

## Usage

```bash
git clone https://github.com/rockerBOO/image_scorer
cd image_scorer
```

### Create images.json

We use `images.json` to create a list of images to rate. Images must be stored in `images/` in the main directory. (Not ideal, but how it works)

```
python make_images_json.py images
```

Puts the `images.json` into `priv/images.json`

These images will be viewable though `images/` URL.

### Web service

Runs the web service for the UI

```bash
gleam run
```

Then you can go to the web service:

```
http://localhost:3000/
```

### Aesthetic prediction and similarity

Running the aesthetic predictive and similarity models. Using poetry to do package management.

```bash
poetry run uvicorn ae_scorer_server:app --port 3031
```

No cross domain implementation, currently.

## Tests

```bash
gleam test
```

## Contribute

Not open for improvements as it's still a work in progress, but any feedback is open and welcome.

## TODO

- Finish rate.html plus/minus
- Finish similarity file upload
- Finish similarity dataset
- Cleanup JS
- Cleanup styling
- Complete model hosting
- Deploy

### Additional improvements

- Save each latent and CLIP image embeddings for the images

## BUGS

There are no bugs. … Gotcha.

### Preference

- Preference when one of the items is 404 causes it the crash and can't proceed
