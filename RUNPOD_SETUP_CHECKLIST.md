# Lc0 RunPod Setup Checklist

## Phase 1: Build image
- [ ] Run `./build-and-push-runpod-image.sh <docker-username>`
- [ ] Confirm image exists on Docker Hub

## Phase 2: RunPod endpoint
- [ ] Create serverless endpoint in RunPod
- [ ] Set image `<docker-username>/woodland-lc0-runpod:latest`
- [ ] Set env vars: `DATABASE_URL`, `LC0_PATH`, `LC0_NODES`, `LC0_NETWORK` (optional)
- [ ] Deploy and copy endpoint ID

## Phase 3: Dispatcher config
- [ ] Set `RUNPOD_LC0_ENDPOINT_ID` in woodland_dispatchers
- [ ] Set `RUNPOD_API_KEY` in woodland_dispatchers
- [ ] Verify `DATABASE_URL` in worker + dispatcher

## Phase 4: End-to-end verify
- [ ] Confirm jobs move from `pending` -> `submitted` -> `completed`
- [ ] Confirm rows in `lc0_game_analysis`
- [ ] Confirm rows in `lc0_move_analysis`
