import torch

# 파일 경로에 맞게 수정
pth_path = 'effb3_t_e50_1e-5.pth'
checkpoint = torch.load(pth_path, map_location='cpu')

# 전체 키와 차원 출력
for k in checkpoint.keys():
    v = checkpoint[k]
    if hasattr(v, 'shape'):
        print(f"{k}: {v.shape}")
    elif isinstance(v, dict):
        for subk in v:
            subv = v[subk]
            if hasattr(subv, 'shape'):
                print(f"{k}.{subk}: {subv.shape}")
