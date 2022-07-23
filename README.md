# Pipelines

This repo contains the service code to deploy and operate a Distributed Container Build System.

As platform teams operate Azure Pipelines they often find themselves depending upon Microsoft Hosted Agents or deploying long-lived Self-Hosted Agents on Virtual Machines. This project aims to provide teams the capability to dynamically provision container based agents with defined properties such as image names / tags, location, namespaces and quantities. As part of the `azure-pipelines.yml` constructs, teams can provision and deprovision agents before and after building, testing and releasing code.

For additional information, please visit the [Wiki](https://github.com/ljtill/pipelines/wiki) section of this repository.

_Please note this repository is under development and subject to change._

---

### Documentation

- Getting Started: [Link](https://github.com/ljtill/pipelines/wiki/getting-started)
- System Design: [Link](https://github.com/ljtill/pipelines/wiki/system-design)
- In-flight Tasks: [Link](https://github.com/ljtill/pipelines/wiki/tasks)

---

### Project Structure

| Folder                  | Description                  |
| ----------------------- | ---------------------------- |
| eng/                    | Project Support Artifacts    |
| eng/configs             | Configuration Files          |
| eng/platform            | Infra-as-Code Components     |
| eng/scripts             | Project Shell Scripts        |
| src/                    | Runtime Source Code          |
| src/Pipelines.Client    | Message Queue Tooling        |
| src/Pipelines.Extension | Azure DevOps Extension Files |
| src/Pipelines.Images    | Pipeline Container Images    |
| src/Pipelines.Runtime   | Azure Functions Source       |
| src/Pipelines.Tests     | Project Test Files           |
