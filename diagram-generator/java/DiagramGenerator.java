import java.io.*;
import java.nio.file.*;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;

/**
 * Architecture Diagram Generator using Java
 * Converts markdown documentation to visual diagrams using PlantUML
 */
public class DiagramGenerator {
    
    private static final String OUTPUT_DIR = "output";
    
    public static void main(String[] args) {
        System.out.println("🎨 Generating Architecture Diagrams...\n");
        
        try {
            Files.createDirectories(Paths.get(OUTPUT_DIR));
            
            generateInfrastructureDiagram();
            generatePKIDiagram();
            generateSecurityLayersDiagram();
            generateRequestFlowDiagram();
            generateNetworkTopologyDiagram();
            generateHTMLViewer();
            
            System.out.println("\n✨ All diagrams generated!");
            System.out.println("\n📁 Output directory: " + OUTPUT_DIR + "/");
            System.out.println("\nGenerated files:");
            System.out.println("  - infrastructure.puml");
            System.out.println("  - pki.puml");
            System.out.println("  - security_layers.puml");
            System.out.println("  - request_flow.puml");
            System.out.println("  - network_topology.puml");
            System.out.println("  - viewer.html");
            
        } catch (IOException e) {
            System.err.println("Error: " + e.getMessage());
            e.printStackTrace();
        }
    }
    
    private static void generateInfrastructureDiagram() throws IOException {
        String content = """
@startuml infrastructure
!define RECTANGLE class

skinparam backgroundColor #FEFEFE
skinparam componentStyle rectangle

package "User Laptop" #E1F5FF {
    [Browser] as browser
}

cloud "GCP Project 1\\ntest-project1-485105\\n(VPN Gateway)" #FFF3CD {
    package "VPC: networkingglobal-vpc\\n20.20.20.0/16" #FFFFCC {
        [Firezone Gateway\\ne2-small\\n20.20.20.10\\nPublic IP] as firezone
    }
}

cloud "GCP Project 2\\ntest-project2-485105\\n(Jenkins Application)" #D4EDDA {
    package "VPC: core-it-vpc\\n10.10.10.0/16" #CCFFCC {
        [Internal Load Balancer\\n10.10.10.100\\nPorts: 443, 8080] as lb
        [Nginx\\nHTTPS:443 → HTTP:8080] as nginx
        [Jenkins VM\\ne2-medium\\n10.10.10.10\\nAir-gapped] as jenkins
    }
}

browser -down-> firezone : VPN Connection\\nWireGuard
firezone -down-> lb : VPC Peering\\n20.20.20.0/24 → 10.10.10.0/24
lb -down-> nginx : Port 443
nginx -down-> jenkins : Port 8080

@enduml
""";
        writeFile("infrastructure.puml", content);
        System.out.println("  ✅ Generated infrastructure.puml");
    }
    
    private static void generatePKIDiagram() throws IOException {
        String content = """
@startuml pki
!theme plain

skinparam backgroundColor #FEFEFE
skinparam rectangleBackgroundColor #FFCCCC
skinparam rectangleBorderColor #CC0000

rectangle "LearningMyWay Root CA" as root #FFCCCC {
    RSA 4096-bit
    Valid: 10 years
    Expires: Feb 13, 2036
    --
    Trust Anchor
}

rectangle "LearningMyWay Intermediate CA" as intermediate #FFFFCC {
    RSA 4096-bit
    Valid: 5 years
    Expires: Feb 12, 2031
    --
    Issues Server Certificates
}

rectangle "jenkins.np.learningmyway.space" as server #CCFFCC {
    RSA 2048-bit
    Valid: 1 year
    Expires: Feb 13, 2027
    SAN: DNS + IP
    --
    Server Certificate
}

root -down-> intermediate : Signs
intermediate -down-> server : Signs

@enduml
""";
        writeFile("pki.puml", content);
        System.out.println("  ✅ Generated pki.puml");
    }
    
    private static void generateSecurityLayersDiagram() throws IOException {
        String content = """
@startuml security_layers
!theme plain

skinparam backgroundColor #FEFEFE

rectangle "Layer 5: TLS Encryption" as layer5 #FF9999 {
    HTTPS with certificate chain
    TLS 1.2/1.3
    Browser shows "Secure" 🔒
}

rectangle "Layer 4: VPN Encryption" as layer4 #FFCC99 {
    WireGuard protocol
    All traffic encrypted
    Modern cryptography
}

rectangle "Layer 3: Firewall Protection" as layer3 #FFFF99 {
    Strict access control
    Only VPN subnet allowed
    Default deny
}

rectangle "Layer 2: VPN Authentication" as layer2 #99FF99 {
    Firezone WireGuard VPN
    User authentication
    Resource-based access
}

rectangle "Layer 1: Network Isolation" as layer1 #99CCFF {
    No public IP on Jenkins
    Air-gapped environment
    VPC peering only
}

layer5 -down-> layer4
layer4 -down-> layer3
layer3 -down-> layer2
layer2 -down-> layer1

@enduml
""";
        writeFile("security_layers.puml", content);
        System.out.println("  ✅ Generated security_layers.puml");
    }
    
    private static void generateRequestFlowDiagram() throws IOException {
        String content = """
@startuml request_flow
!theme plain

skinparam backgroundColor #FEFEFE
skinparam sequenceArrowThickness 2
skinparam roundcorner 20

actor "User Browser" as user
participant "VPN\\nEncryption" as vpn
participant "Firezone\\nGateway" as firezone
participant "VPC\\nPeering" as peering
participant "Load\\nBalancer" as lb
participant "Nginx\\nHTTPS" as nginx
participant "Jenkins\\nHTTP" as jenkins

user -> vpn : 1. HTTPS Request
note right: https://jenkins.np.learningmyway.space

vpn -> firezone : 2. Encrypted via WireGuard
note right: All traffic encrypted

firezone -> peering : 3. Authenticated & Routed
note right: VPN authentication passed

peering -> lb : 4. Routed to 10.10.10.100
note right: VPC peering active

lb -> nginx : 5. Forward to Port 443
note right: Load balancer health check

nginx -> jenkins : 6. Proxy to Port 8080
note right: TLS termination

jenkins --> nginx : 7. HTTP Response
nginx --> lb : 8. HTTPS Response
lb --> peering : 9. Routed back
peering --> firezone : 10. Routed back
firezone --> vpn : 11. Encrypted response
vpn --> user : 12. HTTPS Response
note right: Secure connection 🔒

@enduml
""";
        writeFile("request_flow.puml", content);
        System.out.println("  ✅ Generated request_flow.puml");
    }
    
    private static void generateNetworkTopologyDiagram() throws IOException {
        String content = """
@startuml network_topology
!theme plain

skinparam backgroundColor #FEFEFE

cloud "Internet" #E1F5FF {
    [Client Device] as client
}

cloud "Google Cloud Platform" #F0F0F0 {
    package "Project 1: VPN Gateway" #FFF3CD {
        [Firewall Rules\\nPort 51820 UDP] as fw1
        [Firezone Gateway\\n20.20.20.10] as fz
    }
    
    package "Project 2: Jenkins" #D4EDDA {
        [Firewall Rules\\nPorts 443, 8080] as fw2
        [Load Balancer\\n10.10.10.100] as lb
        [Jenkins VM\\n10.10.10.10] as vm
    }
    
    [VPC Peering\\nBidirectional] as peering
}

client --> fw1 : VPN
fw1 --> fz
fz --> peering
peering --> fw2
fw2 --> lb
lb --> vm

@enduml
""";
        writeFile("network_topology.puml", content);
        System.out.println("  ✅ Generated network_topology.puml");
    }
    
    private static void generateHTMLViewer() throws IOException {
        String timestamp = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
        
        String html = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Jenkins Infrastructure - Architecture Diagrams</title>
    <script src="https://cdn.jsdelivr.net/npm/plantuml-encoder@1.4.0/dist/plantuml-encoder.min.js"></script>
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
        .diagram {
            text-align: center;
            margin: 20px 0;
        }
        .diagram img {
            max-width: 100%;
            height: auto;
            border: 1px solid #ddd;
            border-radius: 4px;
            padding: 10px;
            background: white;
        }
        .footer {
            text-align: center;
            color: #7f8c8d;
            margin-top: 40px;
            padding: 20px;
        }
        .info {
            background: #d1ecf1;
            border-left: 4px solid #0c5460;
            padding: 15px;
            margin: 20px 0;
            border-radius: 4px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🏗️ Jenkins VPN Infrastructure - Architecture Diagrams</h1>
        
        <div class="info">
            <strong>📝 Note:</strong> These diagrams are generated from PlantUML files. 
            To render them, you can:
            <ul style="margin-top: 10px; margin-left: 20px;">
                <li>Use <a href="https://www.plantuml.com/plantuml/" target="_blank">PlantUML Online Server</a></li>
                <li>Install PlantUML locally and run: <code>plantuml *.puml</code></li>
                <li>Use VS Code with PlantUML extension</li>
            </ul>
        </div>
        
        <div class="diagram-section">
            <h2>Infrastructure Architecture</h2>
            <p>Complete end-to-end infrastructure showing both GCP projects, VPCs, and components.</p>
            <div class="diagram">
                <p><em>File: infrastructure.puml</em></p>
            </div>
        </div>
        
        <div class="diagram-section">
            <h2>PKI Certificate Chain</h2>
            <p>3-tier certificate chain: Root CA → Intermediate CA → Server Certificate</p>
            <div class="diagram">
                <p><em>File: pki.puml</em></p>
            </div>
        </div>
        
        <div class="diagram-section">
            <h2>5-Layer Security Architecture</h2>
            <p>Defense-in-depth security model with 5 layers of protection.</p>
            <div class="diagram">
                <p><em>File: security_layers.puml</em></p>
            </div>
        </div>
        
        <div class="diagram-section">
            <h2>Request Flow</h2>
            <p>Complete request flow from user browser to Jenkins and back.</p>
            <div class="diagram">
                <p><em>File: request_flow.puml</em></p>
            </div>
        </div>
        
        <div class="diagram-section">
            <h2>Network Topology</h2>
            <p>Network topology showing firewall rules and routing.</p>
            <div class="diagram">
                <p><em>File: network_topology.puml</em></p>
            </div>
        </div>
        
        <div class="footer">
            <p>Generated on """ + timestamp + """</p>
            <p>Jenkins VPN Infrastructure Documentation</p>
            <p style="margin-top: 10px;">
                <strong>To render diagrams:</strong> 
                <code>java -jar plantuml.jar *.puml</code>
            </p>
        </div>
    </div>
</body>
</html>
""";
        
        writeFile("viewer.html", html);
        System.out.println("  ✅ Generated viewer.html");
    }
    
    private static void writeFile(String filename, String content) throws IOException {
        Path path = Paths.get(OUTPUT_DIR, filename);
        Files.writeString(path, content);
    }
}
