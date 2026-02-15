# 🎨 Architecture Diagram Generators

Three implementations to generate professional architecture diagrams from your Jenkins infrastructure documentation.

## 📁 Structure

```
diagram-generator/
├── python/              # Python + Graphviz
│   ├── generate_diagrams.py
│   └── requirements.txt
├── typescript/          # TypeScript + Mermaid
│   ├── generate-diagrams.ts
│   └── package.json
├── java/                # Java + PlantUML
│   └── DiagramGenerator.java
└── README.md           # This file
```

## 🚀 Quick Start

### Option 1: Python (Easiest) ⭐ RECOMMENDED

**Requirements:** Python 3.7+ and Graphviz

```bash
# Install Graphviz first
# Windows: choco install graphviz
# Mac: brew install graphviz
# Linux: sudo apt-get install graphviz

# Install Python dependencies
cd diagram-generator/python
pip install -r requirements.txt

# Generate diagrams
python generate_diagrams.py

# Output: PNG files in output/ folder
```

**Generates:**
- `infrastructure.png` - Complete infrastructure
- `pki.png` - PKI certificate chain
- `security_layers.png` - 5-layer security
- `request_flow.png` - Request/response flow

---

### Option 2: TypeScript (Modern)

**Requirements:** Node.js 16+

```bash
cd diagram-generator/typescript

# Install dependencies
npm install

# Generate diagrams
npm run generate

# Output: Mermaid files + HTML viewer in output/ folder
```

**Generates:**
- `*.mmd` files (Mermaid diagrams)
- `viewer.html` - Interactive HTML viewer

**Open `output/viewer.html` in browser to see all diagrams!**

---

### Option 3: Java (Enterprise)

**Requirements:** Java 11+

```bash
cd diagram-generator/java

# Compile
javac DiagramGenerator.java

# Run
java DiagramGenerator

# Output: PlantUML files in output/ folder
```

**Generates:**
- `*.puml` files (PlantUML diagrams)
- `viewer.html` - HTML viewer

**To render PlantUML diagrams:**
```bash
# Download PlantUML
wget https://github.com/plantuml/plantuml/releases/download/v1.2024.0/plantuml.jar

# Generate PNG images
java -jar plantuml.jar output/*.puml
```

---

## 📊 Comparison

| Feature | Python | TypeScript | Java |
|---------|--------|------------|------|
| **Setup** | ⭐⭐⭐ Easy | ⭐⭐ Medium | ⭐⭐ Medium |
| **Output** | PNG images | HTML + Mermaid | PlantUML files |
| **Quality** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Interactive** | ❌ No | ✅ Yes | ❌ No |
| **Dependencies** | Graphviz | Node.js | Java + PlantUML |
| **Best For** | Quick PNG export | Web viewing | Enterprise docs |

---

## 🎯 Which One to Use?

### Use Python if:
- ✅ You want PNG images immediately
- ✅ You need high-quality static diagrams
- ✅ You want the simplest setup
- ✅ You're familiar with Python

### Use TypeScript if:
- ✅ You want interactive HTML viewer
- ✅ You prefer modern JavaScript ecosystem
- ✅ You want to embed in web pages
- ✅ You like Mermaid syntax

### Use Java if:
- ✅ You're in an enterprise environment
- ✅ You need PlantUML format
- ✅ You want maximum customization
- ✅ You prefer Java ecosystem

---

## 📋 Generated Diagrams

All three generators create these diagrams:

### 1. Infrastructure Architecture
- Complete end-to-end infrastructure
- Both GCP projects
- VPCs, VMs, networking
- Connection flows

### 2. PKI Certificate Chain
- Root CA
- Intermediate CA
- Server certificate
- Signing relationships

### 3. Security Layers
- 5-layer defense-in-depth
- Network isolation
- VPN authentication
- Firewall protection
- VPN encryption
- TLS encryption

### 4. Request Flow
- User to Jenkins flow
- All intermediate hops
- Encryption layers
- Response path

### 5. Network Topology (TypeScript & Java)
- Network layout
- Firewall rules
- Routing paths

---

## 🎨 Customization

### Python (Graphviz)
Edit `generate_diagrams.py`:
```python
# Change colors
dot.node('jenkins', 'Jenkins VM', fillcolor='#your-color')

# Change layout
dot.attr(rankdir='LR')  # Left to right instead of top to bottom

# Add nodes
dot.node('new_node', 'New Component', fillcolor='#color')
dot.edge('source', 'new_node', label='Connection')
```

### TypeScript (Mermaid)
Edit `generate-diagrams.ts`:
```typescript
// Change diagram type
content: `
sequenceDiagram  // or: graph TB, graph LR, etc.
    ...
`

// Change colors
style Node fill:#your-color
```

### Java (PlantUML)
Edit `DiagramGenerator.java`:
```java
// Change theme
!theme plain  // or: cerulean, sketchy, etc.

// Change colors
skinparam rectangleBackgroundColor #your-color
```

---

## 🖼️ Output Examples

### Python Output
```
output/
├── infrastructure.png
├── pki.png
├── security_layers.png
└── request_flow.png
```

### TypeScript Output
```
output/
├── infrastructure.mmd
├── pki.mmd
├── security_layers.mmd
├── request_flow.mmd
├── network_topology.mmd
└── viewer.html  ← Open this!
```

### Java Output
```
output/
├── infrastructure.puml
├── pki.puml
├── security_layers.puml
├── request_flow.puml
├── network_topology.puml
└── viewer.html
```

---

## 🔧 Troubleshooting

### Python: "graphviz not found"
```bash
# Install Graphviz system package
# Windows
choco install graphviz

# Mac
brew install graphviz

# Linux
sudo apt-get install graphviz

# Then install Python package
pip install graphviz
```

### TypeScript: "Cannot find module"
```bash
# Install dependencies
npm install

# If still fails, try
npm install --save-dev @types/node typescript ts-node
```

### Java: "Class not found"
```bash
# Make sure you're in the java directory
cd diagram-generator/java

# Compile first
javac DiagramGenerator.java

# Then run
java DiagramGenerator
```

---

## 📚 Additional Resources

### Graphviz (Python)
- Documentation: https://graphviz.org/documentation/
- Gallery: https://graphviz.org/gallery/
- Attributes: https://graphviz.org/doc/info/attrs.html

### Mermaid (TypeScript)
- Documentation: https://mermaid.js.org/
- Live Editor: https://mermaid.live/
- Examples: https://mermaid.js.org/syntax/examples.html

### PlantUML (Java)
- Documentation: https://plantuml.com/
- Online Server: https://www.plantuml.com/plantuml/
- Examples: https://real-world-plantuml.com/

---

## 🎯 Recommended Workflow

1. **Start with Python** - Get PNG diagrams quickly
2. **Use TypeScript** - Create interactive HTML viewer
3. **Use Java** - If you need PlantUML for enterprise docs

Or just pick one and stick with it! They all produce great results.

---

## 💡 Pro Tips

1. **Version Control** - Commit the generator code, not the output
2. **Automation** - Add to CI/CD to regenerate on doc changes
3. **Customization** - Modify colors to match your brand
4. **Export** - Use PNG for presentations, HTML for web
5. **Updates** - Regenerate when infrastructure changes

---

## ✅ Summary

You now have **three professional diagram generators** that create beautiful architecture diagrams from your documentation:

- 🐍 **Python** - Quick PNG export
- 📘 **TypeScript** - Interactive HTML viewer
- ☕ **Java** - Enterprise PlantUML

**Pick your favorite and generate diagrams in seconds!** 🎨

---

**Questions?** Check the tool-specific documentation or examples above.
