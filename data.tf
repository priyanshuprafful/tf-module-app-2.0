data "aws_ami" "centos8" {

  owners = ["275396904943"]
  most_recent = true
  name_regex = "centos-8-with-ansible"
}
