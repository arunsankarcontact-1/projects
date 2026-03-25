data "google_project" "project" {}

resource "google_project_iam_member" "cloudbuild_storage_access" {
  project = var.project_id
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${data.google_project.project.number}@cloudbuild.gserviceaccount.com"
}

resource "google_project_iam_member" "compute_storage_access" {
  project = var.project_id
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com"
}
resource "google_project_iam_member" "compute_logging_access" {
  project = var.project_id
  role   = "roles/logging.logWriter"
  member = "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com"
}
resource "google_project_iam_member" "compute_artifact_access" {
  project = var.project_id
  role   = "roles/artifactregistry.reader"
  member = "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com"
}
resource "google_project_iam_member" "compute_artifact_writer" {
  project = var.project_id
  role   = "roles/artifactregistry.writer"
  member = "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com"
}
