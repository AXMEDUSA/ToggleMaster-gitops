#!/usr/bin/env python3
"""
Diagrama animado: ToggleMaster GitOps — Kubernetes + ArgoCD + Observabilidade
Resolução: 720x540  FPS: 12  Duração: ~16s + 2s pausa
"""

from PIL import Image, ImageDraw, ImageFont
import math, os

W, H   = 720, 540
FPS    = 12
FRAMES = FPS * 16
PAUSE  = FPS * 2
OUT    = os.path.join(os.path.dirname(__file__), "togglemaster-gitops.gif")

BG     = (13,  17,  23)
CARD   = (22,  27,  34)
BORDER = (33,  38,  45)
BLUE   = (56,  139, 253)
GREEN  = (63,  185, 80)
ORANGE = (240, 136, 62)
PURPLE = (188, 140, 255)
YELLOW = (227, 179, 65)
RED    = (248, 81,  73)
WHITE  = (230, 237, 243)
DIM    = (139, 148, 158)
DIMMER = (72,  79,  88)
CYAN   = (56,  203, 237)
TEAL   = (0,   188, 188)

def load_font(size):
    for p in ["/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf",
              "/usr/share/fonts/truetype/liberation/LiberationMono-Regular.ttf"]:
        if os.path.exists(p): return ImageFont.truetype(p, size)
    return ImageFont.load_default()

F8  = load_font(8)
F9  = load_font(9)
F10 = load_font(10)
F11 = load_font(11)
F12 = load_font(12)
F13 = load_font(13)
F20 = load_font(20)

def ease(t):      return 1-(1-max(0,min(1,t)))**3
def prog(f,s,e):  return ease((f-s)/(e-s)) if s<f<e else (0. if f<=s else 1.)
def ab(c,a,bg=BG):return tuple(int(bg[i]+(c[i]-bg[i])*a) for i in range(3))

def rr(d,x0,y0,x1,y1,r,fill=None,outline=None,w=1):
    d.rounded_rectangle([x0,y0,x1,y1],radius=r,fill=fill,outline=outline,width=w)

def tc(d,cx,y,t,font,fill):
    bb=d.textbbox((0,0),t,font=font); tw=bb[2]-bb[0]
    d.text((cx-tw//2,y),t,font=font,fill=fill)

def dashed(d,x0,y0,x1,y1,col,dash=7,gap=4,w=1):
    dist=math.hypot(x1-x0,y1-y0)
    if dist==0: return
    ux,uy=(x1-x0)/dist,(y1-y0)/dist
    p,on=0,True
    while p<dist:
        e=min(p+(dash if on else gap),dist)
        if on: d.line([(x0+ux*p,y0+uy*p),(x0+ux*e,y0+uy*e)],fill=col,width=w)
        p=e; on=not on

def dashed_prog(d,x0,y0,x1,y1,col,p_ratio,w=2):
    if p_ratio<=0: return
    ex=x0+(x1-x0)*p_ratio; ey=y0+(y1-y0)*p_ratio
    dashed(d,x0,y0,ex,ey,col,w=w)

def packet(d,x0,y0,x1,y1,p,col,label=""):
    if p<=0 or p>=1: return
    px=int(x0+(x1-x0)*p); py=int(y0+(y1-y0)*p)
    d.ellipse([px-5,py-5,px+5,py+5],fill=col)
    if label: d.text((px+8,py-5),label,font=F8,fill=col)

def node(d,cx,cy,w,h,title,sub,col,a=1.0,badge=None):
    x0,y0,x1,y1=cx-w//2,cy-h//2,cx+w//2,cy+h//2
    rr(d,x0,y0,x1,y1,6,fill=ab(CARD,a),outline=ab(col,a),w=2)
    tc(d,cx,y0+6,title,F11,ab(col,a))
    tc(d,cx,y0+20,sub,F9,ab(DIM,a))
    if badge:
        bw=len(badge)*6+8
        rr(d,x1-bw-2,y0+2,x1-2,y0+14,3,fill=ab(col,a))
        tc(d,x1-bw//2-2,y0+3,badge,F8,ab(BG,a))

def render(f):
    img = Image.new("RGB",(W,H),BG)
    d   = ImageDraw.Draw(img)

    # ── título ──────────────────────────────────────────────
    ta = prog(f,0,8)
    tc(d,W//2,12,"ToggleMaster GitOps",F20,ab(WHITE,ta))
    tc(d,W//2,36,"AKS · ArgoCD · Prometheus · Loki · Grafana",F9,ab(DIM,ta))

    # ── labels de seção ─────────────────────────────────────
    la = prog(f,6,14)
    d.text((18,58),"GITHUB",font=F9,fill=ab(DIM,la))
    d.text((200,58),"ARGOCD",font=F9,fill=ab(DIM,la))
    d.text((390,58),"AKS CLUSTER",font=F9,fill=ab(DIM,la))
    d.text((570,58),"OBSERVABILIDADE",font=F9,fill=ab(DIM,la))

    # ── separadores verticais ────────────────────────────────
    sep_a = prog(f,8,16)
    for sx in [185,375,560]:
        d.line([(sx,52),(sx,H-30)],fill=ab(BORDER,sep_a),width=1)

    # ── COLUNA 1: GitHub ─────────────────────────────────────
    # GitOps Repo
    ga = prog(f,8,18)
    node(d,92,105,140,40,"ToggleMaster-gitops","github.com/AXMEDUSA",BLUE,ga)
    # App Repo
    node(d,92,165,140,40,"ToggleMaster-AppRepo","CI/CD · Docker · ACR",CYAN,ga)

    # ── COLUNA 2: ArgoCD ─────────────────────────────────────
    aa = prog(f,12,22)
    node(d,285,105,140,40,"ArgoCD","sync · selfHeal · prune",ORANGE,aa,"prd")
    # apps
    for i,(name,col) in enumerate([
        ("observability",PURPLE),
        ("flag-service",GREEN),
        ("auth-service",GREEN),
        ("eval-service",GREEN),
        ("analytics",GREEN),
        ("targeting",GREEN),
    ]):
        node(d,285,160+i*46,130,32,name,"Synced ✓",col,aa*prog(f,14+i,22+i))

    # ── COLUNA 3: AKS ────────────────────────────────────────
    ka = prog(f,16,26)
    # namespaces dos microsserviços
    svcs = [
        ("flag-service-prd",  GREEN,  8002),
        ("auth-service-prd",  GREEN,  8001),
        ("eval-service-prd",  GREEN,  8004),
        ("analytics-prd",     YELLOW, 8005),
        ("targeting-prd",     GREEN,  8003),
    ]
    for i,(ns,col,port) in enumerate(svcs):
        ya = ka * prog(f,16+i,24+i)
        node(d,468,100+i*54,150,38,ns,f":{port} · 2 replicas",col,ya)

    # ── COLUNA 4: Observabilidade ────────────────────────────
    oa = prog(f,20,30)
    obs = [
        ("Prometheus","métricas · 15d retention",ORANGE),
        ("Loki","logs · promtail",PURPLE),
        ("Grafana","dashboards · alertas",BLUE),
    ]
    for i,(name,sub,col) in enumerate(obs):
        ya = oa * prog(f,20+i*2,30+i*2)
        node(d,638,110+i*90,128,42,name,sub,col,ya)

    # ── LINHAS: GitHub → ArgoCD ─────────────────────────────
    p1 = prog(f,10,20)
    dashed_prog(d,162,105,215,105,BLUE,p1,w=2)
    pkt1 = (prog(f,20,36)*2)%1.0
    packet(d,162,105,215,105,pkt1,CYAN,"push")

    # ── LINHAS: ArgoCD → AKS (microsserviços) ───────────────
    p2 = prog(f,18,28)
    for i in range(5):
        dashed_prog(d,350,160+i*46,393,100+i*54,GREEN,p2,w=1)

    # ── LINHAS: ArgoCD → Observabilidade ────────────────────
    p3 = prog(f,22,32)
    dashed_prog(d,350,105,574,110,ORANGE,p3,w=2)
    dashed_prog(d,350,105,574,200,PURPLE,p3*0.8,w=2)
    dashed_prog(d,350,105,574,290,BLUE,  p3*0.6,w=2)

    # ── LINHA: Prometheus/Loki → Grafana (scrape) ───────────
    p4 = prog(f,30,40)
    dashed_prog(d,638,152,638,220,DIM,p4,w=1)
    dashed_prog(d,638,242,638,268,DIM,p4,w=1)
    pkt2 = (prog(f,38,54)*2)%1.0
    packet(d,638,152,638,265,pkt2,ORANGE,"scrape")

    # ── LINHA: Promtail coleta logs dos pods ─────────────────
    p5 = prog(f,28,38)
    dashed_prog(d,468,300,574,242,PURPLE,p5,w=1)
    pkt3 = (prog(f,36,52)*2)%1.0
    packet(d,468,300,574,242,pkt3,PURPLE,"logs")

    # ── terminal inferior ────────────────────────────────────
    term_a = prog(f,34,44)
    rr(d,10,H-90,W-10,H-10,6,fill=ab(CARD,term_a),outline=ab(BORDER,term_a),w=1)
    lines = [
        (BLUE,  "$ ","argocd app list"),
        (GREEN, "● ","observability   Synced   Healthy"),
        (GREEN, "● ","flag-service    Synced   Healthy"),
        (DIM,   "$ ","kubectl get pods -n observability"),
        (GREEN, "  ","prometheus-server   2/2   Running   grafana   3/3   Running"),
    ]
    for i,(col,prefix,txt) in enumerate(lines):
        ya = term_a * prog(f,34+i*2,44+i*2)
        d.text((18,H-84+i*14),prefix,font=F9,fill=ab(col,ya))
        d.text((34,H-84+i*14),txt,  font=F9,fill=ab(WHITE if col==BLUE else col,ya))

    # ── watermark ───────────────────────────────────────────
    d.text((W-160,H-14),"fxshell | togglemaster-gitops",font=F8,fill=DIMMER)

    return img

frames = []
for f in range(FRAMES):
    frames.append(render(f))
for _ in range(PAUSE):
    frames.append(render(FRAMES-1))

frames[0].save(
    OUT, save_all=True, append_images=frames[1:],
    optimize=False, loop=0,
    duration=int(1000/FPS)
)
print(f"GIF salvo: {OUT}  ({len(frames)} frames)")
