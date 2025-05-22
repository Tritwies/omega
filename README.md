# Tritwies + Zed Integration

Tritwies is a toolkit for advanced agent interaction and hypergraph visualization, with specific focus on knowledge representation and distributed cognition. This repository now integrates with Zed, a high-performance, multiplayer code editor.

## Tritwies Components

### Hypergraphistry-MCP

Hypergraphistry-MCP provides a Model Context Protocol (MCP) interface for creating, manipulating, and visualizing hypergraphs. It integrates with Graphistry for GPU-accelerated graph visualization.

### Discopy-MCP

DisCoPy integration for compositional diagram creation and manipulation through the Model Context Protocol.

### Graphistry-MCP

GPU-accelerated graph visualization with pattern detection capabilities through the Model Context Protocol.

### OpenAI Agents MCP

Agent architecture implementation using OpenAI's SDK with MCP integration.

## Zed Editor

Welcome to Zed, a high-performance, multiplayer code editor from the creators of [Atom](https://github.com/atom/atom) and [Tree-sitter](https://github.com/tree-sitter/tree-sitter).

### Installation

On macOS and Linux you can [download Zed directly](https://zed.dev/download) or [install Zed via your local package manager](https://zed.dev/docs/linux#installing-via-a-package-manager).

Other platforms are not yet available:

- Windows ([tracking issue](https://github.com/zed-industries/zed/issues/5394))
- Web ([tracking issue](https://github.com/zed-industries/zed/issues/5396))

### Developing Zed

- [Building Zed for macOS](./docs/src/development/macos.md)
- [Building Zed for Linux](./docs/src/development/linux.md)
- [Building Zed for Windows](./docs/src/development/windows.md)
- [Running Collaboration Locally](./docs/src/development/local-collaboration.md)

## Development

### Setup

```bash
# Clone the repository
git clone https://github.com/yourusername/Tritwies.git
cd Tritwies

# Set up virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
```

### Running MCP Servers

Each MCP server can be started individually or through a unified runner:

```bash
# Run a specific MCP server
python -m hypergraphistry_mcp.standalone_server

# Or use the MCP CLI to manage servers
mcp server start --name hypergraphistry-mcp
```

## Staging

See `exa-mcp-staging-plan.md` for details on staging the Exa MCP server for production use.

## License

This project is dual-licensed:
- Tritwies components: MIT license
- Zed components: See Zed licensing documentation for details