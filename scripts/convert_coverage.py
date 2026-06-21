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
    
    # xccov JSON has a top-level 'files' array
    files = data if isinstance(data, list) else data.get('files', [])
    
    for file_data in files:
        path = file_data.get('path', file_data.get('name', ''))
        if not path or not path.endswith('.swift'):
            continue
        
        # Normalize path
        if path.startswith('/'):
            path = path[1:]
        
        line_coverage = file_data.get('lineCoverage', 0.0)
        executable = file_data.get('executableLines', 0)
        covered = file_data.get('coveredLines', 0)
        
        file_el = ET.SubElement(coverage, 'file', path=path)
        
        # Try to get line-level data
        lines = file_data.get('lines', [])
        if lines:
            for line in lines:
                ln = line.get('lineNumber', line.get('line', 0))
                executed = line.get('isExecutable', line.get('executed', False))
                if ln and executed:
                    ET.SubElement(file_el, 'lineToCover', lineNumber=str(ln), coverage='100')
        elif executable > 0:
            # Use summary data
            cov_pct = int(line_coverage * 100) if line_coverage else 0
            if covered > 0:
                ET.SubElement(file_el, 'lineToCover', lineNumber='1', coverage=str(cov_pct))
    
    xml_str = ET.tostring(coverage, encoding='unicode')
    pretty_xml = minidom.parseString(xml_str).toprettyxml(indent='  ')
    
    with open(output_path, 'w') as f:
        f.write(pretty_xml)
    
    # Count files processed
    file_count = len([f for f in coverage.findall('file')])
    print(f"Converted {xccov_json_path} to {output_path} ({file_count} files)")

if __name__ == '__main__':
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <input.json> <output.xml>")
        sys.exit(1)
    convert(sys.argv[1], sys.argv[2])
