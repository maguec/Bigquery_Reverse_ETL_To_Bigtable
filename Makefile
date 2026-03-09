default: bundletf

bundletf:
	rm -f Terraform.zip
	zip --include '*.tf' '*.sh' '*.yaml' '*.ctmpl' '*.csv' -rj  Terraform.zip  Terraform/


docs:
	rm -f Qwiklabs.pdf
	pandoc -s -o QwiklabsScript.pdf QwiklabScript.md

