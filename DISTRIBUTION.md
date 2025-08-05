In this first part of the interview, you will build a comprehensive chatbot system that leverages Retrieval
Augmented Generation (RAG). This project will involve creating a chat application with a backend that
integrates RAG functionality to enhance LLM responses with retrieved context from a knowledge base.
Your completed system will enable users to ask questions through an intuitive interface and receive
informed responses that combine the power of large language models with domain-specific knowledge
retrieved from your indexed documentation. The system will maintain conversation context to provide
coherent, multi-turn interactions while ensuring the LLM has access to the most relevant information for
each query.
The architecture integrates the RAG functionality directly within the chat backend service, allowing it to
seamlessly retrieve contextual information and generate enhanced responses. For this project, feel free
to use any and all resources available to you, including LLMs like ChatGPT for assistance with
implementation details.
Requirements
Chatbot Implementation
• Create a functional chatbot using any framework of your choice (e.g., React, Vue, Angular for
frontend; Node.js, Python/Flask, etc. for backend)
• Implement a clean, intuitive user interface for conversation
• Feel free to leverage existing open-source solutions or libraries to accelerate development
RAG System Architecture
• Implement RAG functionality:
o Maintains a vector database of document embeddings
o Implements similarity search to find relevant context based on user queries
o Retrieves contextually relevant information and integrates it with LLM responses
o You may use existing open source RAG implementations as a foundation
• Design the backend to:
o Process user queries and retrieve relevant context from the indexed knowledge base
o Use an LLM to generate responses based on user queries and the retrieved context
o Provide a seamless integration between retrieval and response generation
Technical Specifications
• IMPORTANT: Use the following dataset for RAG indexing: https://huggingface.co/datasets/rag-
datasets/rag-mini-wikipedia
• Document the architecture of your solution, clearly showing how RAG functionality is integrated
within the backend
• Include instructions for setting up and running your application
• Explain design decisions and any tradeoffs made
Evaluation Criteria
• Functionality: Does the chatbot work as expected?
• Code quality: Is the code clean, maintainable, and well-structured?
• Architecture: Is the system designed with appropriate separation of concerns and proper
integration of RAG functionality?
• Documentation: Is the solution well-documented?
Recommended Resources
Model Engines
You can use any foundational model APIs or local models for your implementation, including:
• Ollama: Run large language models locally on your own hardware with an easy-to-use interface
for deploying and running various open-source models. https://ollama.com/
• vLLM: A high-throughput and memory-efficient inference engine for LLMs that enables faster
serving with optimized attention algorithms. https://github.com/vllm-project/vllm
• OpenAI API: Use models like GPT-4 or GPT-3.5 through OpenAI's API for powerful language
capabilities.
• Anthropic Claude API: Leverage Claude models for safe, helpful, and harmless AI interactions.
• Local Models: Implement with open-source models like Llama, Mistral, or others that can run on
your infrastructure.
Document Indexing & Vector Databases
• LangChain: Framework for developing applications powered by language models with built-in
document loading and indexing capabilities.
• LlamaIndex: Data framework for building LLM applications with tools for ingesting, structuring,
and accessing private or domain-specific data.
• Vector Databases:
o Chroma: Open-source embedding database designed for AI applications
o Pinecone: Vector database for semantic search and similarity matching
o Weaviate: Open-source vector search engine
o FAISS: Library for efficient similarity search from Meta Research
• Text Embedding Models:
o OpenAI Embeddings: Like text-embedding-3-small or text-embedding-3-large
o HuggingFace Models: Various embedding models available through the Transformers
library
o Sentence Transformers: Specialized models for creating semantically meaningful
embeddings
• Data to Index: https://huggingface.co/datasets/rag-datasets/rag-mini-wikipedia