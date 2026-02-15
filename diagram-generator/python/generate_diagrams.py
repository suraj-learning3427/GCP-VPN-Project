#!/usr/bin/env python3
"""
Architecture Diagram Generator using Python
Converts markdown documentation to visual diagrams using Graphviz
"""

from graphviz import Digraph
import os

def create_infrastructure_diagram():
    """Create infrastructure architecture diagram"""
    dot = Digraph(comment='Jenkins VPN Infrastructure', format='png')
    dot.attr(rankdir='TB', splines='ortho', nodesep='1', ranksep='1.5')
    dot.attr('node', shape='box', style='rounded,filled', fontname='Arial')
    
    # User/Client
    with dot.subgraph(name='cluster_user') as c:
        c.attr(label='User Laptop', style='filled', color='lightblue')
        c.node('user', 'User\nBrowser', fillcolor='#e1f5ff')
    
    # GCP Project 1 - VPN Gateway
    with dot.subgraph(name='cluster_project1') as c:
        c.attr(label='GCP Project 1\ntest-project1-485105\n(VPN Gateway)', 
               style='filled', color='lightgray')
        
        with c.subgraph(name='cluster_vpc1') as vpc:
            vpc.attr(label='VPC: networkingglobal-vpc\n20.20.20.0/16', 
                    style='dashed', color='blue')
            vpc.node('firezone', 'Firezone Gateway\ne2-small\n20.20.20.10\nPublic IP', 
                    fillcolor='#fff3cd')
    
    # GCP Project 2 - Jenkins
    with dot.subgraph(name='cluster_project2') as c:
        c.attr(label='GCP Project 2\ntest-project2-485105\n(Jenkins Application)', 
               style='filled', color='lightgray')
        
        with c.subgraph(name='cluster_vpc2') as vpc:
            vpc.attr(label='VPC: core-it-vpc\n10.10.10.0/16', 
                    style='dashed', color='blue')
            
            vpc.node('lb', 'Internal Load Balancer\n10.10.10.100\nPorts: 443, 8080', 
                    fillcolor='#d4edda')
            vpc.node('jenkins', 'Jenkins VM\ne2-medium\n10.10.10.10\nAir-gapped', 
                    fillcolor='#d1ecf1')
            vpc.node('nginx', 'Nginx\nHTTPS:443 → HTTP:8080', 
                    fillcolor='#d1ecf1')
    
    # Connections
    dot.edge('user', 'firezone', label='VPN\nWireGuard', color='green', style='bold')
    dot.edge('firezone', 'lb', label='VPC Peering\n20.20.20.0/24 → 10.10.10.0/24', 
            color='blue', style='bold')
    dot.edge('lb', 'nginx', label='Port 443', color='red')
    dot.edge('nginx', 'jenkins', label='Port 8080', color='orange')
    
    return dot

def create_pki_diagram():
    """Create PKI certificate chain diagram"""
    dot = Digraph(comment='PKI Certificate Chain', format='png')
    dot.attr(rankdir='TB', nodesep='1', ranksep='1')
    dot.attr('node', shape='box', style='rounded,filled', fontname='Arial')
    
    # Root CA
    dot.node('root', 'LearningMyWay Root CA\n\nRSA 4096-bit\nValid: 10 years\nExpires: Feb 13, 2036', 
            fillcolor='#ffcccc', shape='box3d')
    
    # Intermediate CA
    dot.node('intermediate', 'LearningMyWay Intermediate CA\n\nRSA 4096-bit\nValid: 5 years\nExpires: Feb 12, 2031', 
            fillcolor='#ffffcc', shape='box3d')
    
    # Server Certificate
    dot.node('server', 'jenkins.np.learningmyway.space\n\nRSA 2048-bit\nValid: 1 year\nExpires: Feb 13, 2027\nSAN: DNS + IP', 
            fillcolor='#ccffcc', shape='box3d')
    
    # Connections
    dot.edge('root', 'intermediate', label='Signs', color='blue', style='bold')
    dot.edge('intermediate', 'server', label='Signs', color='blue', style='bold')
    
    return dot

def create_security_layers_diagram():
    """Create 5-layer security architecture diagram"""
    dot = Digraph(comment='Security Layers', format='png')
    dot.attr(rankdir='TB', nodesep='0.5', ranksep='0.8')
    dot.attr('node', shape='box', style='filled', fontname='Arial', width='4')
    
    # Security layers from top to bottom
    dot.node('layer5', 'Layer 5: TLS Encryption\n\nHTTPS with certificate chain\nTLS 1.2/1.3\nBrowser shows "Secure" 🔒', 
            fillcolor='#ff9999')
    dot.node('layer4', 'Layer 4: VPN Encryption\n\nWireGuard protocol\nAll traffic encrypted\nModern cryptography', 
            fillcolor='#ffcc99')
    dot.node('layer3', 'Layer 3: Firewall Protection\n\nStrict access control\nOnly VPN subnet allowed\nDefault deny', 
            fillcolor='#ffff99')
    dot.node('layer2', 'Layer 2: VPN Authentication\n\nFirezone WireGuard VPN\nUser authentication\nResource-based access', 
            fillcolor='#99ff99')
    dot.node('layer1', 'Layer 1: Network Isolation\n\nNo public IP on Jenkins\nAir-gapped environment\nVPC peering only', 
            fillcolor='#99ccff')
    
    # Connections
    dot.edge('layer5', 'layer4', style='bold', arrowsize='1.5')
    dot.edge('layer4', 'layer3', style='bold', arrowsize='1.5')
    dot.edge('layer3', 'layer2', style='bold', arrowsize='1.5')
    dot.edge('layer2', 'layer1', style='bold', arrowsize='1.5')
    
    return dot

def create_request_flow_diagram():
    """Create request flow diagram"""
    dot = Digraph(comment='Request Flow', format='png')
    dot.attr(rankdir='LR', nodesep='1', ranksep='1')
    dot.attr('node', shape='box', style='rounded,filled', fontname='Arial')
    
    # Flow nodes
    dot.node('1', '1. User\nBrowser', fillcolor='#e1f5ff')
    dot.node('2', '2. VPN\nEncryption', fillcolor='#fff3cd')
    dot.node('3', '3. Firezone\nGateway', fillcolor='#fff3cd')
    dot.node('4', '4. VPC\nPeering', fillcolor='#d4edda')
    dot.node('5', '5. Load\nBalancer', fillcolor='#d4edda')
    dot.node('6', '6. Nginx\nHTTPS', fillcolor='#d1ecf1')
    dot.node('7', '7. Jenkins\nHTTP', fillcolor='#d1ecf1')
    
    # Flow
    dot.edge('1', '2', label='HTTPS Request', color='red')
    dot.edge('2', '3', label='Encrypted', color='green')
    dot.edge('3', '4', label='Authenticated', color='blue')
    dot.edge('4', '5', label='Routed', color='blue')
    dot.edge('5', '6', label='Port 443', color='red')
    dot.edge('6', '7', label='Port 8080', color='orange')
    
    # Return flow
    dot.edge('7', '6', label='Response', color='gray', style='dashed')
    dot.edge('6', '5', label='Encrypted', color='gray', style='dashed')
    dot.edge('5', '4', label='Routed', color='gray', style='dashed')
    dot.edge('4', '3', label='Routed', color='gray', style='dashed')
    dot.edge('3', '2', label='Encrypted', color='gray', style='dashed')
    dot.edge('2', '1', label='HTTPS Response', color='gray', style='dashed')
    
    return dot

def main():
    """Generate all diagrams"""
    output_dir = 'output'
    os.makedirs(output_dir, exist_ok=True)
    
    print("🎨 Generating Architecture Diagrams...")
    
    # Generate diagrams
    diagrams = {
        'infrastructure': create_infrastructure_diagram(),
        'pki': create_pki_diagram(),
        'security_layers': create_security_layers_diagram(),
        'request_flow': create_request_flow_diagram()
    }
    
    # Render diagrams
    for name, diagram in diagrams.items():
        print(f"  ✅ Generating {name}.png...")
        diagram.render(f'{output_dir}/{name}', cleanup=True)
    
    print(f"\n✨ All diagrams generated in '{output_dir}/' folder!")
    print("\nGenerated files:")
    for name in diagrams.keys():
        print(f"  - {name}.png")

if __name__ == '__main__':
    main()
