import xml
import xml.etree.ElementTree as ET


def set_xml_field(xml_fname, field_name, value):
    tree = ET.parse(xml_fname)

    root = tree.getroot()

    field = root.find(field_name)
    field.text = str(value)

    tree.write(xml_fname)
