"""
Policy-as-code ITS - CKV_ITS_1
Capitolato Portale ITS, requisito di governance: ogni risorsa taggabile deve
portare il tag Owner, cioè la squadra responsabile. Un check scritto una volta
e valido su entrambi i binari: CloudFormation e Terraform.
"""
from checkov.common.models.enums import CheckCategories, CheckResult
from checkov.cloudformation.checks.resource.base_resource_check import (
    BaseResourceCheck as BaseCfnCheck,
)
from checkov.terraform.checks.resource.base_resource_check import (
    BaseResourceCheck as BaseTfCheck,
)

ID = "CKV_ITS_1"
NOME = "Ogni risorsa del portale deve avere il tag Owner (capitolato ITS)"
GUIDA = "Aggiungi il tag Owner con il nome della squadra responsabile della risorsa."


class TagOwnerCloudFormation(BaseCfnCheck):
    def __init__(self) -> None:
        super().__init__(
            name=NOME,
            id=ID,
            categories=[CheckCategories.CONVENTION],
            supported_resources=[
                "AWS::S3::Bucket",
                "AWS::DynamoDB::Table",
            ],
            guideline=GUIDA,
        )

    def scan_resource_conf(self, conf):
        # In CloudFormation i tag sono una lista: [{Key: ..., Value: ...}, ...]
        tags = (conf.get("Properties") or {}).get("Tags") or []
        if isinstance(tags, dict):
            tags = [tags]
        for tag in tags:
            if not isinstance(tag, dict):
                continue
            if str(tag.get("Key", "")).lower() == "owner" and str(tag.get("Value", "")).strip():
                return CheckResult.PASSED
        return CheckResult.FAILED


class TagOwnerTerraform(BaseTfCheck):
    def __init__(self) -> None:
        super().__init__(
            name=NOME,
            id=ID,
            categories=[CheckCategories.CONVENTION],
            supported_resources=[
                "aws_s3_bucket",
                "aws_dynamodb_table",
            ],
            guideline=GUIDA,
        )

    def scan_resource_conf(self, conf):
        # In Terraform i tag sono una mappa, incapsulata in una lista dal parser
        tags = conf.get("tags")
        if isinstance(tags, list) and tags:
            tags = tags[0]
        if isinstance(tags, dict):
            for chiave, valore in tags.items():
                if str(chiave).lower() == "owner" and str(valore).strip():
                    return CheckResult.PASSED
        return CheckResult.FAILED


check_cfn = TagOwnerCloudFormation()
check_tf = TagOwnerTerraform()
