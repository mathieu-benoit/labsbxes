# Architecture: `docker compose up` vs `sbx run`

Both setups give the learner the same thing: instructions on the left, VS Code on the right, and a Docker engine to run the exercises against. What changes is where everything runs and what keeps the learner's Docker usage contained.

## Before: `docker compose up` (labspace-infra)

Six containers share your host's Docker engine. The learner's `docker` commands reach that engine through `socket-proxy`, which labels, filters and remaps every call so the lab only sees, mounts and later deletes its own resources. A separate container republishes learner ports, and another one cleans up on `docker compose down`.

```mermaid
graph TD
    User(["Learner"])

    subgraph Host["Host machine"]
        direction TB

        subgraph Stack["docker compose up: 6 containers"]
            direction TB
            Configurator["configurator<br/>one-shot: git clone, keys, metadata"]
            Interface["interface :3030<br/>instructions UI"]
            Workspace["workspace :8085<br/>code-server + support extension"]
            SocketProxy["socket-proxy<br/>labels, filters, remaps mounts"]
            Republisher["host-port-republisher<br/>socat per learner port"]
            Cleaner["workspace-cleaner<br/>removes labeled resources on down"]
        end

        Volumes["5 named volumes<br/>content, instructions, support,<br/>proxied docker.sock, docker creds"]

        HostEngine["Host Docker Engine<br/>shared with everything else on the host"]

        subgraph LearnerRes["Learner workloads, on the host"]
            direction TB
            LearnerCtr["containers, volumes, networks<br/>labeled labspace-resource=true"]
        end
    end

    subgraph External["External"]
        direction TB
        ContentRepo["Content git repo"]
        Hub["Docker Hub"]
    end

    User -->|docker compose up| Configurator
    User -->|browser :3030| Interface
    User -->|browser :8085| Workspace
    Configurator -->|git clone| ContentRepo
    Configurator -->|fills| Volumes
    Interface -->|reads instructions| Volumes
    Workspace -->|project files| Volumes
    Interface -->|JWT over unix socket| Workspace
    Workspace -->|docker CLI| SocketProxy
    SocketProxy -->|filtered API calls| HostEngine
    HostEngine -->|runs| LearnerCtr
    HostEngine -->|pulls images| Hub
    Republisher -->|forwards ports| LearnerCtr
    Cleaner -->|removes on down| LearnerCtr

    %% Styles — containers
    style Host fill:#E5F2FC,stroke:#1D63ED,color:#00084D
    style Stack fill:#f0f7ff,stroke:#7aaede,color:#00084D
    style LearnerRes fill:#f0faf4,stroke:#86c5a0,color:#00084D
    style External fill:#fff7f0,stroke:#d4915e,color:#00084D

    %% Styles — actor
    style User fill:#fff,stroke:#1D63ED,color:#00084D

    %% Styles — user-facing services
    style Interface fill:#fff,stroke:#0DB7ED,color:#384D54
    style Workspace fill:#fff,stroke:#0DB7ED,color:#384D54

    %% Styles — plumbing services
    style Configurator fill:#E5F2FC,stroke:#0DB7ED,color:#384D54
    style SocketProxy fill:#E5F2FC,stroke:#0DB7ED,color:#384D54
    style Republisher fill:#E5F2FC,stroke:#0DB7ED,color:#384D54
    style Cleaner fill:#E5F2FC,stroke:#0DB7ED,color:#384D54
    style Volumes fill:#f8fbff,stroke:#9fc5e8,color:#384D54

    %% Styles — infrastructure
    style HostEngine fill:#E5F2FC,stroke:#1D63ED,color:#00084D

    %% Styles — learner workloads
    style LearnerCtr fill:#e0f2e6,stroke:#6db88a,color:#384D54

    %% Styles — external
    style ContentRepo fill:#fff0e5,stroke:#d4915e,color:#384D54
    style Hub fill:#fff0e5,stroke:#d4915e,color:#384D54
```

## After: `sbx run` (this repo)

One Docker Sandbox, a microVM, per lab. Its image is composed from kits: the `shell` workload (Debian with Docker), the Labspace kit (code-server, the interface, the scripts and a built-in getting-started lab), and optionally a content kit. The learner's `docker` talks to an engine that only exists inside that VM, so there is nothing to proxy, and `sbx rm` removes everything the lab created.

```mermaid
graph TD
    User(["Learner"])

    subgraph Host["Host machine"]
        direction TB
        Sbx["sbx run shell --kit labspace<br/>[--kit content] [lab folder]"]
        Ports["Published ports on 127.0.0.1<br/>3030, 8085, appPort"]
        HostFolder["Lab folder, optional<br/>labspace/ + project/"]
    end

    subgraph Sandbox["Docker Sandbox, a microVM"]
        direction TB

        subgraph Image["Composed image"]
            direction LR
            Shell["shell workload<br/>Debian, Docker engine"]
            LabspaceKit["Labspace kit<br/>code-server, interface,<br/>built-in lab"]
            ContentKit["Content kit, optional<br/>labspace/ + project/"]
        end

        Stage["labspace-stage.sh, every boot<br/>lab folder, else content kit,<br/>else built-in lab"]
        Interface["interface :3030<br/>instructions UI"]
        CodeServer["code-server :8085<br/>+ support extension"]
        Dockerd["Private Docker engine<br/>dockerd@1, only this lab"]

        subgraph LearnerRes["Learner workloads, in the VM"]
            direction TB
            LearnerCtr["containers, volumes, networks"]
        end
    end

    subgraph External["External"]
        direction TB
        Registry["Kit registry<br/>ghcr.io"]
        Hub["Docker Hub<br/>allowed by network policy"]
    end

    User -->|sbx run| Sbx
    User -->|browser| Ports
    Sbx -->|pulls kits| Registry
    Sbx -->|composes and boots| Shell
    Sbx -->|publishes| Ports
    HostFolder -->|mounted as workspace| Stage
    LabspaceKit -->|built-in lab| Stage
    ContentKit -->|lab content| Stage
    Stage -->|instructions| Interface
    Stage -->|project folder| CodeServer
    Ports -->|:3030| Interface
    Ports -->|:8085| CodeServer
    Interface -->|JWT over unix socket| CodeServer
    CodeServer -->|docker CLI| Dockerd
    Shell -->|starts| Dockerd
    Dockerd -->|runs| LearnerCtr
    Dockerd -->|pulls images| Hub

    %% Styles — containers
    style Host fill:#E5F2FC,stroke:#1D63ED,color:#00084D
    style Sandbox fill:#E5F2FC,stroke:#1D63ED,color:#00084D
    style Image fill:#f0f7ff,stroke:#7aaede,color:#00084D
    style LearnerRes fill:#f0faf4,stroke:#86c5a0,color:#00084D
    style External fill:#fff7f0,stroke:#d4915e,color:#00084D

    %% Styles — actor
    style User fill:#fff,stroke:#1D63ED,color:#00084D

    %% Styles — host side
    style Sbx fill:#E5F2FC,stroke:#1D63ED,color:#00084D
    style Ports fill:#fff,stroke:#1D63ED,color:#00084D
    style HostFolder fill:#e0f2e6,stroke:#6db88a,color:#384D54

    %% Styles — kits
    style Shell fill:#fff,stroke:#0DB7ED,color:#384D54
    style LabspaceKit fill:#fff,stroke:#0DB7ED,color:#384D54
    style ContentKit fill:#fff,stroke:#0DB7ED,color:#384D54

    %% Styles — runtime processes
    style Stage fill:#E5F2FC,stroke:#0DB7ED,color:#384D54
    style Interface fill:#fff,stroke:#0DB7ED,color:#384D54
    style CodeServer fill:#fff,stroke:#0DB7ED,color:#384D54
    style Dockerd fill:#E5F2FC,stroke:#1D63ED,color:#00084D

    %% Styles — learner workloads
    style LearnerCtr fill:#e0f2e6,stroke:#6db88a,color:#384D54

    %% Styles — external
    style Registry fill:#fff0e5,stroke:#d4915e,color:#384D54
    style Hub fill:#fff0e5,stroke:#d4915e,color:#384D54
```

## The differences at a glance

| | `docker compose up` | `sbx run` |
|---|---|---|
| Isolation boundary | Containers on your host's engine; `socket-proxy` filters the Docker API | A microVM with its own kernel and its own Docker engine |
| Learner's `docker` | Host engine, through the proxied socket | Private engine inside the VM (`dockerd@1`) |
| Where the lab comes from | `configurator` clones a git repo into volumes | A lab folder, a content kit, or the built-in getting-started lab, picked at each boot |
| Ports | 3030 and 8085, plus `host-port-republisher` for learner apps | 3030, 8085 and `appPort` published by the runtime (`port@1`) |
| Network egress | Unrestricted | Allow-list from the kits' network policy |
| Cleanup | `workspace-cleaner` on `docker compose down` | `sbx rm` deletes the VM and its engine store |
| Moving parts | 6 containers, 5 volumes, 1 network, 5 configs | 1 workload kit + the Labspace kit, plus an optional content kit |

Components that disappeared: `socket-proxy`, `workspace-cleaner`, `host-port-republisher`, and the `configurator` container (replaced by two small boot scripts). The interface and the VS Code support extension are reused unchanged from the images labspace-infra publishes.

> [!NOTE]
> This shows `main` today, where the interface and the IDE are published on two ports (3030 and 8085). [#1](https://github.com/mathieu-benoit/labsbxes/pull/1) adds a small gateway that serves both on a single port.
