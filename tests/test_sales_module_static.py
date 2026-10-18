"""Fast checks for the XML-based Odoo 19 Sales configuration (no Odoo server needed)."""

import ast
from pathlib import Path
import unittest
from xml.etree import ElementTree as ET


ROOT = Path(__file__).resolve().parents[1]
ADDON = ROOT / "addons" / "eigen_sales_config"


class SalesModuleStaticTest(unittest.TestCase):
    def test_manifest_declares_dependency_and_installability(self):
        manifest = ast.literal_eval((ADDON / "__manifest__.py").read_text(encoding="utf-8"))
        self.assertIn("sale_management", manifest["depends"])
        self.assertEqual(manifest["data"], ["data/sales_defaults.xml"])
        self.assertTrue(manifest["installable"])
        self.assertFalse(manifest["auto_install"])

    def test_xml_only_updates_default_company_with_expected_fields(self):
        root = ET.parse(ADDON / "data" / "sales_defaults.xml").getroot()
        self.assertEqual(root.tag, "odoo")
        self.assertEqual(root.findall(".//record"), [])
        self.assertEqual(root.findall(".//data[@noupdate='1']"), [])
        functions = root.findall("function")
        self.assertEqual(len(functions), 1)
        self.assertEqual(functions[0].get("model"), "res.company")
        self.assertEqual(functions[0].get("name"), "write")
        calls = []

        def resolve_xmlid(xmlid):
            calls.append(xmlid)
            return 101

        # The XML is code owned by this repository; the test uses only a restricted namespace.
        arguments = eval(functions[0].get("eval"), {"__builtins__": {}}, {"ref": resolve_xmlid})
        self.assertEqual(calls, ["base.main_company"])
        self.assertEqual(arguments, [[101], {
            "quotation_validity_days": 21,
            "portal_confirmation_sign": True,
            "portal_confirmation_pay": False,
        }])

    def test_no_enterprise_dependency(self):
        manifest = ast.literal_eval((ADDON / "__manifest__.py").read_text(encoding="utf-8"))
        self.assertEqual(manifest["depends"], ["sale_management"])


if __name__ == "__main__":
    unittest.main()
