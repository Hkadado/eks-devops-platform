resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "7.7.0"
  namespace        = "argocd"
  create_namespace = true

  values = [file("${path.module}/argocd-values.yaml")]

  # Argo CD takes a bit to fully initialize after the helm install reports success.
  # Without this, the bootstrap Application apply can race against the CRDs.
  wait          = true
  wait_for_jobs = true
}

resource "kubectl_manifest" "bootstrap" {
  depends_on = [helm_release.argocd]
  yaml_body  = file("${path.module}/bootstrap-app.yaml")
}