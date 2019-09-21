
variable "aws_secret_key"{
  type = "string"
}

variable "aws_access_key"{
   type = "string"
}


provider "aws" {
        region = "us-east-2"
        secret_key = "${var.aws_secret_key}"
        access_key = "${var.aws_access_key}"
}


resource "aws_vpc" "vpc_test" {
  cidr_block = "10.0.0.0/16"
  instance_tenancy = "default"
}

resource "aws_subnet" "subnet_test" {
  vpc_id                  = "${aws_vpc.vpc_test.id}"
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-2a"
}

resource "aws_subnet" "subnet_test2" {
  vpc_id                  = "${aws_vpc.vpc_test.id}"
  cidr_block              = "10.0.5.0/24"
  availability_zone       = "us-east-2b"
}


resource "aws_security_group" "sg_test" {
  vpc_id       = "${aws_vpc.vpc_test.id}"
  name         = "sg_test"
  description  = "for demo"


egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
  }
}

resource "aws_network_acl" "acl_test" {
  vpc_id = "${aws_vpc.vpc_test.id}"
  subnet_ids = [ "${aws_subnet.subnet_test.id}" ]
# allow port 22
  ingress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
# allow egress ephemeral ports
  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
}

resource "aws_internet_gateway" "igw_test" {
  vpc_id = "${aws_vpc.vpc_test.id}"
}


resource "aws_route_table" "rt_test" {
    vpc_id = "${aws_vpc.vpc_test.id}"
}

resource "aws_route" "internet_access_test" {
  route_table_id        = "${aws_route_table.rt_test.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.igw_test.id}"
}


resource "aws_route_table_association" "My_VPC_association" {
    subnet_id      = "${aws_subnet.subnet_test.id}"
    route_table_id = "${aws_route_table.rt_test.id}"
}

resource "aws_route_table_association" "My_VPC2_association" {
    subnet_id      = "${aws_subnet.subnet_test2.id}"
    route_table_id = "${aws_route_table.rt_test.id}"
}



resource "aws_iam_role" "role_test" {
  name = "eks-testing"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "demo-cluster-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = "${aws_iam_role.role_test.name}"
}

resource "aws_iam_role_policy_attachment" "demo-cluster-AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = "${aws_iam_role.role_test.name}"
}






resource "aws_eks_cluster" "eks-test" {
   name     = "eks-test"
   role_arn = "${aws_iam_role.role_test.arn}"

   vpc_config {
    security_group_ids = ["${aws_security_group.sg_test.id}"]
    subnet_ids = ["${aws_subnet.subnet_test.id}", "${aws_subnet.subnet_test2.id}"]
   }

}

output "endpoint" {
  value = "${aws_eks_cluster.eks-test.endpoint}"
}

output "kubeconfig-certificate-authority-data" {
  value = "${aws_eks_cluster.eks-test.certificate_authority.0.data}"
}

