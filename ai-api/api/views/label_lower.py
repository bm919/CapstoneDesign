# 영어 키워드 → 한글 라벨 매핑
ENGLISH_LABEL_MAP = {
    "beverage_can": "캔류",
    "canned_can": "캔류",
    "glass_beer_bottle": "유리류",
    "glass_clear_bottle": "유리류",
    "glass_tableware": "유리류",
    "metal_pot": "고철류",
    "paper_book": "책자",
    "paper_box": "상자",
    "paper_news": "신문지",
    "plastic_bottle": "플라스틱류",
    "plastic_crushed": "플라스틱류",
    "plastic_cup_container": "플라스틱류",
    "vinyl": "비닐류",
}

# 한글 키워드 매핑 (라벨명, 키워드 리스트)
HANGL_LABEL_MAP = [
    ("고철류", ["고철", "쇠붙이", "스테인리스", "철사", "철판", "비철금속", "알루미늄", "스텐"]),
    ("비닐류", ["비닐", "vinyl", "필름류"]),
    ("상자류", ["상자", "골판지", "박스"]),
    ("소형가전류", ["소형폐가전", "소형가전", "음식물처리기", "전기밥솥", "청소기"]),
    ("신문지류", ["신문지"]),
    ("유리류", ["유리", "유리병", "병", "glass"]),
    ("음식물 쓰레기", ["음식물 쓰레기", "음식물쓰레기"]),
    ("의류류", ["의류", "헌옷", "신발", "가방", "담요", "옷"]),
    ("전자제품류", ["전자제품", "대형가전", "TV", "냉장고", "세탁기", "에어컨", "컴퓨터", "오디오", "휴대폰", "폐전자제품"]),
    ("전지류", ["전지류", "건전지", "폐건전지", "배터리"]),
    ("책자류", ["책자", "노트", "책", "달력", "공책", "잡지", "종이 쇼핑백", "전단지", "포장지"]),
    ("캔류", ["캔류", "음료수캔", "맥주캔", "식료품 캔", "알루미늄캔", "철캔", "부탄가스", "살충제 용기", "기타 캔"]),
    ("플라스틱류", ["플라스틱", "PET", "플라스틱병", "플라스틱 용기", "플라스틱 컵", "플라스틱 컨테이너", "페트병"]),
    ("형광등류", ["형광등", "폐형광등", "전구"]),
]

def classify_label(text: str) -> str:
    """텍스트에서 라벨 추출 (영어 키, 한글 텍스트 모두 지원)"""
    if not isinstance(text, str):
        return "기타"
    key = text.strip().lower()
    
    # 영어 코드 매핑 우선
    if key in ENGLISH_LABEL_MAP:
        return ENGLISH_LABEL_MAP[key]
    
    # 한글 키워드 매핑
    for label, keywords in HANGL_LABEL_MAP:
        for kw in keywords:
            if kw.lower() in key:
                return label
    return "기타"
