# Contributing to Vendor 2025 Authentication Stack

Thank you for your interest in contributing to this project! This document provides guidelines and information for contributors.

## 🚀 Getting Started

### Prerequisites
- Node.js 18+ and npm
- Docker and Docker Compose
- Kubernetes cluster (for K8s deployment)
- Git

### Development Setup
```bash
# Clone the repository
git clone git@github.com:chingnokas/vendor2025-app.git
cd vendor2025-app

# Install frontend dependencies
npm install

# Install backend dependencies
cd backend
npm install
cd ..

# Start development environment
docker-compose up --build
```

## 📋 Development Workflow

### 1. Create a Feature Branch
```bash
git checkout -b feature/your-feature-name
```

### 2. Make Your Changes
- Follow the existing code style
- Add tests for new functionality
- Update documentation as needed

### 3. Test Your Changes
```bash
# Test Docker Compose deployment
./test-stack.sh

# Test Kubernetes deployment (if applicable)
./k8s/test-k8s-stack.sh
```

### 4. Commit Your Changes
```bash
git add .
git commit -m "feat: add your feature description"
```

### 5. Push and Create Pull Request
```bash
git push origin feature/your-feature-name
```

## 🧪 Testing Guidelines

### Frontend Testing
```bash
# Run Angular tests
npm test

# Run e2e tests
npm run e2e
```

### Backend Testing
```bash
cd backend
npm test
```

### Integration Testing
```bash
# Test complete stack
./test-stack.sh

# Test specific components
curl http://localhost:3002/health
```

## 📝 Code Style

### Frontend (Angular)
- Follow Angular style guide
- Use TypeScript strict mode
- Implement proper error handling
- Use reactive forms

### Backend (Express.js)
- Use ES6+ features
- Implement proper error handling
- Follow RESTful API conventions
- Use middleware for common functionality

### Database
- Use proper SQL practices
- Implement database migrations
- Use prepared statements

## 🔒 Security Guidelines

- Never commit sensitive information (passwords, keys)
- Use environment variables for configuration
- Implement proper input validation
- Follow OWASP security guidelines

## 📚 Documentation

- Update README.md for new features
- Add inline code comments
- Update API documentation
- Include deployment notes

## 🐛 Bug Reports

When reporting bugs, please include:
- Steps to reproduce
- Expected behavior
- Actual behavior
- Environment details
- Screenshots (if applicable)

## 💡 Feature Requests

For feature requests, please provide:
- Clear description of the feature
- Use case and benefits
- Possible implementation approach
- Any relevant examples

## 📞 Getting Help

- Check existing issues and documentation
- Create an issue for questions
- Join discussions in pull requests

## 🏷️ Commit Message Format

Use conventional commits:
- `feat:` new feature
- `fix:` bug fix
- `docs:` documentation changes
- `style:` formatting changes
- `refactor:` code refactoring
- `test:` adding tests
- `chore:` maintenance tasks

## 📋 Pull Request Checklist

- [ ] Code follows project style guidelines
- [ ] Tests pass locally
- [ ] Documentation updated
- [ ] No sensitive information committed
- [ ] Branch is up to date with main
- [ ] Clear description of changes

Thank you for contributing! 🎉
