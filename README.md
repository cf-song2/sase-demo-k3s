# Zero Trust Demo Environment

Cloudflare Zero Trust 데모 환경 구축 프로젝트

## 아키텍처

```
Client VM (Ubuntu Desktop + WARP)
        │
        │ WARP Tunnel
        │
Cloudflare Edge
        │
Cloudflare Tunnel
        │
cloudflared Pod (Kubernetes)
        │
Kubernetes Cluster (k3s)
 ├── web service (HTTP)
 ├── ssh service
 ├── rdp service
 └── smb service
```

### 접근 방식

| 서비스 | 접근 방식 | 포트 |
|--------|-----------|------|
| HTTP   | Public Hostname (Clientless) | 80 |
| SSH    | WARP private network | 22 |
| RDP    | WARP private network | 3389 |
| SMB    | WARP private network | 445 |

## 환경 요구사항

### Server VM
- **OS**: Ubuntu Server 22.04 ARM
- **CPU**: 4 cores
- **RAM**: 6GB
- **Disk**: 40GB
- **역할**: k3s, Kubernetes workloads, cloudflared tunnel

### Client VM
- **OS**: Ubuntu Desktop 22.04 ARM
- **CPU**: 2 cores
- **RAM**: 4GB
- **Disk**: 30GB
- **역할**: Cloudflare WARP client, SSH/RDP/SMB 테스트

## 프로젝트 구조

```
zero-trust-demo/
├── README.md
├── .gitignore
├── scripts/
│   ├── install-k3s.sh
│   └── deploy.sh
└── k8s/
    ├── namespace.yaml
    ├── web.yaml
    ├── ssh.yaml
    ├── rdp.yaml
    ├── smb.yaml
    ├── kustomization.yaml
    └── cloudflared/
        ├── configmap.yaml
        └── deployment.yaml
```

## 네트워크 설계

### Service CIDR
```
10.43.0.0/16 (k3s default)
```

### 고정 Service IP

| 서비스 | ClusterIP  | 용도 |
|--------|------------|------|
| SSH    | 10.43.0.22 | WARP private routing |
| RDP    | 10.43.0.39 | WARP private routing |
| SMB    | 10.43.0.45 | WARP private routing |

## 설치 가이드

### 1. Server VM 설정

k3s 설치:

```bash
cd zero-trust-demo
chmod +x scripts/install-k3s.sh
./scripts/install-k3s.sh
```

설치 확인:

```bash
kubectl get nodes
kubectl get pods -A
```

### 2. Cloudflare Tunnel 설정

Tunnel 생성:

```bash
cloudflared tunnel create demo-tunnel
```

생성된 credentials.json 파일을 저장합니다.

ConfigMap 수정 (`k8s/cloudflared/configmap.yaml`):

```yaml
tunnel: YOUR_TUNNEL_ID
```

```yaml
- hostname: web-demo.example.com
```

Secret 생성:

```bash
kubectl create namespace demo
kubectl create secret generic cloudflared-creds \
  --from-file=credentials.json=/path/to/credentials.json \
  -n demo
```

### 3. Cloudflare Dashboard 설정

Public Hostname 추가:
- Subdomain: web-demo
- Domain: example.com
- Service: http://web.demo.svc.cluster.local:80

Private Network 추가:
- CIDR: 10.43.0.0/16

### 4. 배포

```bash
cd zero-trust-demo
chmod +x scripts/deploy.sh
./scripts/deploy.sh
```

배포 확인:

```bash
kubectl get pods -n demo
kubectl get svc -n demo
```

## Client VM 설정

WARP 클라이언트를 설치하고 Zero Trust 조직에 연결합니다.

```bash
warp-cli register
warp-cli connect
warp-cli teams-enroll YOUR_TEAM_NAME
```

## 테스트

### HTTP (Public Hostname)

브라우저에서:
```
https://web-demo.example.com
```

### SSH (WARP Private Network)

```bash
ssh demo@10.43.0.22
```

Username: demo / Password: demo

### RDP (WARP Private Network)

```bash
remmina
```

Server: 10.43.0.39:3389

### SMB (WARP Private Network)

```
smb://10.43.0.45
```

Username: demo / Password: demo

## 트러블슈팅

Pod 상태 확인:

```bash
kubectl describe pod <pod-name> -n demo
kubectl logs <pod-name> -n demo
```

cloudflared 설정 확인:

```bash
kubectl get configmap cloudflared-config -n demo -o yaml
```

WARP 상태 확인:

```bash
warp-cli status
```

## 정리

리소스 삭제:

```bash
kubectl delete namespace demo
```

k3s 제거:

```bash
/usr/local/bin/k3s-uninstall.sh
```

## 완료 기준

- [ ] 모든 Pod가 Running 상태
- [ ] HTTP 접속 가능
- [ ] SSH 접속 가능
- [ ] RDP 접속 가능
- [ ] SMB 접속 가능
