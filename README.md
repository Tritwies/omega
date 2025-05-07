# Tritwies

Tritwies is a toolkit for advanced agent interaction and hypergraph visualization, with specific focus on knowledge representation and distributed cognition.

## Components

### Hypergraphistry-MCP

Hypergraphistry-MCP provides a Model Context Protocol (MCP) interface for creating, manipulating, and visualizing hypergraphs. It integrates with Graphistry for GPU-accelerated graph visualization.

### Discopy-MCP

DisCoPy integration for compositional diagram creation and manipulation through the Model Context Protocol.

### Graphistry-MCP

GPU-accelerated graph visualization with pattern detection capabilities through the Model Context Protocol.

### OpenAI Agents MCP

Agent architecture implementation using OpenAI's SDK with MCP integration.

## MCP Server Configuration

The repository includes configuration for multiple MCP servers in `.mcp.json`, including:

- Hypergraphistry
- Graphistry
- Exa Search
- DisCoPy
- Various utility servers

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

MIT