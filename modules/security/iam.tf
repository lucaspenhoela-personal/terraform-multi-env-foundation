# Data source para montar a trust policy. Preferivel a JSON em heredoc:
# o Terraform valida a estrutura e o resultado sai normalizado.
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "instance" {
  name               = "${local.name_prefix}-instance-role"
  description        = "Role assumida pelas instancias EC2 do ambiente ${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = {
    Name = "${local.name_prefix}-instance-role"
  }
}

# Policy gerenciada pela AWS. Habilita Session Manager, que substitui SSH:
# sem porta 22 aberta, sem chave privada para vazar, e com log de sessao.
resource "aws_iam_role_policy_attachment" "ssm" {
  count = var.enable_ssm_access ? 1 : 0

  role       = aws_iam_role.instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# O instance profile e o invólucro que permite anexar uma role a uma EC2.
# A role sozinha nao pode ser atribuida a uma instancia.
resource "aws_iam_instance_profile" "instance" {
  name = "${local.name_prefix}-instance-profile"
  role = aws_iam_role.instance.name

  tags = {
    Name = "${local.name_prefix}-instance-profile"
  }
}
