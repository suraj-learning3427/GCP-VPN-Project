/**
 * Architecture Diagram Generator using TypeScript
 * Converts markdown documentation to visual diagrams using Mermaid
 */

import * as fs from 'fs';
import * as path from 'path';

interface DiagramConfig {
    name: string;
    title: string;
    content: string;
}

class DiagramGenerator {
    private outputDir: string;

    constructor(outputDir: string = 'output') {
        this.outputDir = outputDir;
        this.ensureOutputDir();
    }

    private ensureOutputDir(): void {
        if (!fs.existsSync(this.outputDir)) {
            fs.mkdirSync(this.outputDir, { recursive: true });
        }
    }

    private createInfrastructureDiagram(): DiagramConfig {
        return {
            name: 'infrastructure',
            title: 'Jenkins VPN Infrastructure Architecture',
            content: `
graph TB
    subgraph User["👤 User Laptop"]
        Browser["Browser<br/>HTTPS Client"]
    end
    
    subgraph Project1["☁️ GCP Project 1: test-project1-485105<br/>(VPN Gateway)"]
        subgraph VPC1["🌐 VPC: networkingglobal-vpc<br/>20.20.20.0/16"]
            Firezone["🔐 Firezone Gateway<br/>e2-small<br/>20.20.20.10<br/>Public IP"]
        end
    end
    
    subgraph Project2["☁️ GCP Project 2: test-project2-485105<br/>(Jenkins Application)"]
        subgraph VPC2["🌐 VPC: core-it-vpc<br/>10.10.10.0/16"]
            LB["⚖️ Internal Load Balancer<br/>10.10.10.100<br/>Ports: 443, 8080"]
            Nginx["🔒 Nginx<br/>HTTPS:443 → HTTP:8080"]
            Jenkins["🏗️ Jenkins VM<br/>e2-medium<br/>10.10.10.10<br/>Air-gapped"]
        end
    end
    
    Browser -->|"VPN Connection<br/>WireGuard"| Firezone
    Firezone -->|"VPC Peering<br/>20.20.20.0/24 → 10.10.10.0/24"| LB
    LB -->|"Port 443"| Nginx
    Nginx -->|"Port 8080"| Jenkins
    
    style User fill:#e1f5ff
    style Project1 fill:#fff3cd
    style Project2 fill:#d4edda
    style VPC1 fill:#ffffcc
    style VPC2 fill:#ccffcc
    style Firezone fill:#ffcccc
    style LB fill:#ccffff
    style Nginx fill:#ffccff
    style Jenkins fill:#ccccff
`
        };
    }

    private createPKIDiagram(): DiagramConfig {
        return {
            name: 'pki',
            title: 'PKI Certificate Chain Architecture',
            content: `
graph TB
    Root["🔐 LearningMyWay Root CA<br/><br/>RSA 4096-bit<br/>Valid: 10 years<br/>Expires: Feb 13, 2036<br/><br/>Trust Anchor"]
    Intermediate["🔑 LearningMyWay Intermediate CA<br/><br/>RSA 4096-bit<br/>Valid: 5 years<br/>Expires: Feb 12, 2031<br/><br/>Issues Server Certificates"]
    Server["📜 jenkins.np.learningmyway.space<br/><br/>RSA 2048-bit<br/>Valid: 1 year<br/>Expires: Feb 13, 2027<br/>SAN: DNS + IP<br/><br/>Server Certificate"]
    
    Root -->|"Signs"| Intermediate
    Intermediate -->|"Signs"| Server
    
    style Root fill:#ffcccc
    style Intermediate fill:#ffffcc
    style Server fill:#ccffcc
`
        };
    }

    private createSecurityLayersDiagram(): DiagramConfig {
        return {
            name: 'security_layers',
            title: '5-Layer Security Architecture',
            content: `
graph TB
    Layer5["🔒 Layer 5: TLS Encryption<br/><br/>HTTPS with certificate chain<br/>TLS 1.2/1.3<br/>Browser shows 'Secure' 🔒"]
    Layer4["🔐 Layer 4: VPN Encryption<br/><br/>WireGuard protocol<br/>All traffic encrypted<br/>Modern cryptography"]
    Layer3["🛡️ Layer 3: Firewall Protection<br/><br/>Strict access control<br/>Only VPN subnet allowed<br/>Default deny"]
    Layer2["🔑 Layer 2: VPN Authentication<br/><br/>Firezone WireGuard VPN<br/>User authentication<br/>Resource-based access"]
    Layer1["🌐 Layer 1: Network Isolation<br/><br/>No public IP on Jenkins<br/>Air-gapped environment<br/>VPC peering only"]
    
    Layer5 --> Layer4
    Layer4 --> Layer3
    Layer3 --> Layer2
    Layer2 --> Layer1
    
    style Layer5 fill:#ff9999
    style Layer4 fill:#ffcc99
    style Layer3 fill:#ffff99
    style Layer2 fill:#99ff99
    style Layer1 fill:#99ccff
`
        };
    }

    private createRequestFlowDiagram(): DiagramConfig {
        return {
            name: 'request_flow',
            title: 'Complete Request Flow',
            content: `
sequenceDiagram
    participant User as 👤 User Browser
    participant VPN as 🔐 VPN Encryption
    participant FZ as 🔑 Firezone Gateway
    participant Peer as 🌐 VPC Peering
    participant LB as ⚖️ Load Balancer
    participant Nginx as 🔒 Nginx HTTPS
    participant Jenkins as 🏗️ Jenkins HTTP
    
    User->>VPN: 1. HTTPS Request
    Note over User,VPN: https://jenkins.np.learningmyway.space
    
    VPN->>FZ: 2. Encrypted via WireGuard
    Note over VPN,FZ: All traffic encrypted
    
    FZ->>Peer: 3. Authenticated & Routed
    Note over FZ,Peer: VPN authentication passed
    
    Peer->>LB: 4. Routed to 10.10.10.100
    Note over Peer,LB: VPC peering active
    
    LB->>Nginx: 5. Forward to Port 443
    Note over LB,Nginx: Load balancer health check
    
    Nginx->>Jenkins: 6. Proxy to Port 8080
    Note over Nginx,Jenkins: TLS termination
    
    Jenkins-->>Nginx: 7. HTTP Response
    Nginx-->>LB: 8. HTTPS Response
    LB-->>Peer: 9. Routed back
    Peer-->>FZ: 10. Routed back
    FZ-->>VPN: 11. Encrypted response
    VPN-->>User: 12. HTTPS Response
    Note over User,VPN: Secure connection 🔒
`
        };
    }

    private createNetworkTopologyDiagram(): DiagramConfig {
        return {
            name: 'network_topology',
            title: 'Network Topology',
            content: `
graph LR
    subgraph Internet["🌍 Internet"]
        Client["Client Device"]
    end
    
    subgraph GCP["☁️ Google Cloud Platform"]
        subgraph P1["Project 1: VPN Gateway"]
            FW["Firewall Rules<br/>Port 51820 UDP"]
            FZ["Firezone Gateway<br/>20.20.20.10"]
        end
        
        subgraph P2["Project 2: Jenkins"]
            FW2["Firewall Rules<br/>Ports 443, 8080"]
            LB["Load Balancer<br/>10.10.10.100"]
            VM["Jenkins VM<br/>10.10.10.10"]
        end
        
        Peering["VPC Peering<br/>Bidirectional"]
    end
    
    Client -->|"VPN"| FW
    FW --> FZ
    FZ --> Peering
    Peering --> FW2
    FW2 --> LB
    LB --> VM
    
    style Internet fill:#e1f5ff
    style GCP fill:#f0f0f0
    style P1 fill:#fff3cd
    style P2 fill:#d4edda
`
        };
    }

    public generateAll(): void {
        console.log('🎨 Generating Architecture Diagrams...\n');

        const diagrams: DiagramConfig[] = [
            this.createInfrastructureDiagram(),
            this.createPKIDiagram(),
            this.createSecurityLayersDiagram(),
            this.createRequestFlowDiagram(),
            this.createNetworkTopologyDiagram()
        ];

        diagrams.forEach(diagram => {
            this.generateDiagram(diagram);
        });

        this.generateHTMLViewer(diagrams);

        console.log('\n✨ All diagrams generated!');
        console.log(`\n📁 Output directory: ${this.outputDir}/`);
        console.log('\nGenerated files:');
        diagrams.forEach(d => console.log(`  - ${d.name}.mmd`));
        console.log('  - viewer.html (Open this to view all diagrams)');
    }

    private generateDiagram(config: DiagramConfig): void {
        const filename = path.join(this.outputDir, `${config.name}.mmd`);
        fs.writeFileSync(filename, config.content.trim());
        console.log(`  ✅ Generated ${config.name}.mmd`);
    }

    private generateHTMLViewer(diagrams: DiagramConfig[]): void {
        const html = `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Jenkins Infrastructure - Architecture Diagrams</title>
    <script src="https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js"></script>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: #f5f5f5;
            padding: 20px;
        }
        .container { max-width: 1400px; margin: 0 auto; }
        h1 {
            color: #2c3e50;
            margin-bottom: 30px;
            text-align: center;
        }
        .diagram-section {
            background: white;
            padding: 30px;
            margin-bottom: 30px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .diagram-section h2 {
            color: #34495e;
            margin-bottom: 20px;
            padding-bottom: 10px;
            border-bottom: 3px solid #3498db;
        }
        .mermaid {
            text-align: center;
            margin: 20px 0;
        }
        .footer {
            text-align: center;
            color: #7f8c8d;
            margin-top: 40px;
            padding: 20px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🏗️ Jenkins VPN Infrastructure - Architecture Diagrams</h1>
        
        ${diagrams.map(d => `
        <div class="diagram-section">
            <h2>${d.title}</h2>
            <div class="mermaid">
                ${d.content.trim()}
            </div>
        </div>
        `).join('\n')}
        
        <div class="footer">
            <p>Generated on ${new Date().toLocaleDateString()}</p>
            <p>Jenkins VPN Infrastructure Documentation</p>
        </div>
    </div>
    
    <script>
        mermaid.initialize({ 
            startOnLoad: true,
            theme: 'default',
            securityLevel: 'loose'
        });
    </script>
</body>
</html>
        `;

        const filename = path.join(this.outputDir, 'viewer.html');
        fs.writeFileSync(filename, html.trim());
        console.log(`  ✅ Generated viewer.html`);
    }
}

// Main execution
const generator = new DiagramGenerator();
generator.generateAll();
