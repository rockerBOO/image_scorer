import { test, expect } from '@playwright/test';

test('index', async ({ page }) => {
	await page.goto('/');

	await expect(page).toHaveTitle(/Image scorer/);
});

test('similarity', async ({ page }) => {
	await page.goto('/similarity.html');

	await expect(page).toHaveTitle(/Similarity/);
});

test('ratings', async ({ page }) => {
	await page.goto('/ratings.html');

	await expect(page).toHaveTitle(/Ratings/);
});

test('rate', async ({ page }) => {
	await page.goto('/rate.html');

	await expect(page).toHaveTitle(/Rate/);
});

test('preference', async ({ page }) => {
	await page.goto('/preference.html');

	await expect(page).toHaveTitle(/Preference/);
});
