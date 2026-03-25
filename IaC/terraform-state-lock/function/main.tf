provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_project_service" "required_apis" {
  for_each = toset([
    "cloudfunctions.googleapis.com",
    "cloudbuild.googleapis.com",
    "artifactregistry.googleapis.com",
    "storage.googleapis.com",
  ])

  service = each.key
}

resource "google_storage_bucket" "function_bucket" {
  name     = "${var.project_id}-function-bucket"
  location = var.region
  uniform_bucket_level_access = true
}

resource "google_storage_bucket_object" "archive" {
  name   = "function.zip"
  bucket = google_storage_bucket.function_bucket.name
  source = "function.zip"
}

resource "google_cloudfunctions_function" "function" {
  name        = "test-function"
  runtime     = "python39"
  entry_point = "hello_world"

  source_archive_bucket = google_storage_bucket.function_bucket.name
  source_archive_object = google_storage_bucket_object.archive.name

  trigger_http = true
  available_memory_mb = 128
  depends_on = [
    google_project_service.required_apis,
    google_project_iam_member.cloudbuild_storage_access,
    google_project_iam_member.compute_storage_access,
    google_project_iam_member.compute_logging_access,
    google_project_iam_member.compute_artifact_access,
    google_project_iam_member.compute_artifact_writer
  ]
}
