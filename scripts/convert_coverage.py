#!/usr/bin/env python3
"""Convert xccov JSON to SonarCloud Generic Coverage Report XML format."""

import json
import sys
import xml.etree.ElementTree as ET
from xml.dom import minidom

def convert(xccov_json_path, output_path):
    with open(xccov_json_path, 'r') as f:
        data = json.load(f)
    
    coverage = ET.Element('coverage', version='1')
    
    for file_data in data.get('files', []):
        path = file_data.get('path', '')
        if not path or not path.endswith('.swift'):
            continue
        
        # Normalize path - remove leading slash and make relative
        if path.startswith('/'):
            path = path[1:]
        
        executable = file_data.get('executableLines', 0)
        covered = file_data.get('coveredLines', 0)
        line_coverage = file_data.get('lineCoverage', 0.0)
        
        file_el = ET.SubElement(coverage, 'file', path=path)
        
        # Add line coverage data
        lines_data = file_data.get('lines', [])
        if not lines_data:
            # Use summary data if no line-level data
            line_el = ET.SubElement(file_el, 'lineToCover', lineNumber='1', coverage=str(int(line_coverage * 100)))
    
    xml_str = ET.tostring(coverage, encoding='unicode')
    pretty_xml = minidom.parseString(xml_str).toprettyxml(indent='  ')
    
    with open(output_path, 'w') as f:
        f.write(pretty_xml)
    
    print(f"Converted {xccov_json_path} to {output_path}")

if __name__ == '__main__':
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <input.json> <output.xml>")
        sys.exit(1)
    convert(sys.argv[1], sys.argv[2])
