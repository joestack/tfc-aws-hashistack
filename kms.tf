//--------------------------------------------------------------------
// KMS Resources for Vault auto-unsealing

resource "aws_kms_key" "vault" {
  count                   = var.vault_enabled ? 1 : 0
  description             = "Vault unseal key"
  deletion_window_in_days = 7

  tags = {
    Name = "${var.name}-vault-kms-unseal-key"
  }
}

resource "aws_kms_alias" "vault" {
  count         = var.vault_enabled ? 1 : 0
  name          = "alias/${var.name}-vault-kms-unseal-key"
  target_key_id = aws_kms_key.vault.*.key_id[count.index]
}