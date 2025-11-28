#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
سكريبت لنسخ مواضع \n من aya_text في quran_hafs.json إلى warshData_v2-1.json
بحيث تكون في نفس المواضع بالضبط (بناءً على عدد الكلمات)
"""

import json
import re
from typing import Optional, List, Dict
import argparse

# نطاق تشكيل العربية لإزالته عند المطابقة
ARABIC_DIACRITICS_PATTERN = re.compile(r"[\u064B-\u065F\u0670\u06D6-\u06ED]")

def strip_diacritics(s: str) -> str:
    """
    إزالة التشكيل والرموز الزائدة لتسهيل المطابقة بين الكلمات.
    """
    # إزالة التشكيل
    s = ARABIC_DIACRITICS_PATTERN.sub('', s)
    # إزالة التطويل والرموز الزخرفية
    s = s.replace('\u0640', '')  # tatweel
    # تطبيع الهمزات والألفات واليا
    s = s.replace('أ', 'ا').replace('إ', 'ا').replace('آ', 'ا')
    s = s.replace('ٱ', 'ا')
    s = s.replace('ى', 'ي')
    # إزالة العلامات الوقفية
    s = re.sub(r'[\u06D6-\u06ED\uFD3E\uFD3F\uFDF2]', '', s)
    # تطبيع المسافات
    s = re.sub(r"\s+", " ", s)
    return s.strip()

ARABIC_INDIC_DIGITS = {ord('٠'): '0', ord('١'): '1', ord('٢'): '2', ord('٣'): '3', ord('٤'): '4', ord('٥'): '5', ord('٦'): '6', ord('٧'): '7', ord('٨'): '8', ord('٩'): '9'}
def parse_ayah_number(val) -> Optional[int]:
    """يحاول تحويل رقم آية قد يكون أرقام عربية/هندية أو نص إلى int."""
    if val is None:
        return None
    try:
        if isinstance(val, int):
            return val
        s = str(val).strip()
        s = s.translate(ARABIC_INDIC_DIGITS)
        return int(s)
    except Exception:
        return None
    

def get_word_positions_with_newlines(text):
    """
    تحليل النص وإيجاد مواضع \n بناءً على عدد الكلمات
    Returns: قائمة بأرقام الكلمات التي يأتي بعدها \n
    """
    # تقسيم النص إلى أجزاء بناءً على \n
    parts = text.split('\n')
    
    if len(parts) == 1:
        # لا يوجد \n في النص
        return []
    
    newline_positions = []
    word_count = 0
    
    # لكل جزء من الأجزاء (عدا الأخير)
    for i, part in enumerate(parts[:-1]):
        # عد الكلمات في هذا الجزء
        words = part.strip().split()
        word_count += len(words)
        # موضع \n يأتي بعد آخر كلمة في هذا الجزء
        newline_positions.append(word_count)
    
    return newline_positions

def map_positions_hafs_to_warsh(hafs_text: str, warsh_text: str, hafs_newline_positions: list[int]) -> list[int]:
    """
    تحويل مواضع \n المحسوبة على نص حفص إلى مواضع مناظرة على نص ورش
    عبر مطابقة الكلمات بدون تشكيل وبترتيب تسلسلي.
    """
    # كلمات بدون تشكيل (بدون إزالة أرقام الآية)
    hafs_words = [w for w in hafs_text.strip().split() if w]
    warsh_words = [w for w in warsh_text.strip().split() if w]
    hafs_norm = [strip_diacritics(w) for w in hafs_words]
    warsh_norm = [strip_diacritics(w) for w in warsh_words]

    # مواءمة عبر n-gram محلي لتجاوز اختلافات الحروف/التشكيل
    n = len(hafs_norm)
    mlen = len(warsh_norm)
    mapping = [None] * n
    k = 4  # حجم النافذة للمطابقة المحلية
    for i in range(n):
        # نافذة كلمات من حفص بدءًا من i
        hafs_ng = tuple(hafs_norm[i:min(i+k, n)])
        best_j = None
        best_score = -1
        # بحث في ورش عن أفضل تطابق لهذه النافذة
        for j in range(0, mlen):
            warsh_ng = tuple(warsh_norm[j:min(j+k, mlen)])
            # قياس تقاطع الكلمات في النافذة
            inter = len(set(hafs_ng) & set(warsh_ng))
            # منح وزن لمطابقة أول كلمة تحديدًا
            if warsh_norm[j] == hafs_norm[i]:
                inter += 1
            if inter > best_score:
                best_score = inter
                best_j = j
        mapping[i] = best_j

    # تحويل مواضع \n: كل موضع هو بعد كلمة حفص رقم k -> بعد كلمة ورش المناظرة
    warsh_positions = []
    for pos in hafs_newline_positions:
        idx_in_hafs = pos - 1  # بعد الكلمة رقم pos يعني الكلمة ذات الفهرس pos-1
        if 0 <= idx_in_hafs < len(mapping) and mapping[idx_in_hafs] is not None:
            warsh_positions.append(mapping[idx_in_hafs] + 1)
        else:
            # إن تعذّرت المطابقة نستخدم موضع تقريبي عبر النسبة
            if len(hafs_words) and len(warsh_words):
                approx = round(pos * len(warsh_words) / len(hafs_words))
                approx = max(1, min(approx, len(warsh_words)))
                warsh_positions.append(approx)

    # إزالة التكرار وترتيب
    warsh_positions = sorted(set(warsh_positions))
    return warsh_positions

def verse_similarity(a_text: str, b_text: str) -> float:
    """تشابه بسيط بين آيتين بالاعتماد على كلمات بدون تشكيل (Jaccard)."""
    a_tokens = set(strip_diacritics(a_text).split())
    b_tokens = set(strip_diacritics(b_text).split())
    if not a_tokens or not b_tokens:
        return 0.0
    inter = len(a_tokens & b_tokens)
    union = len(a_tokens | b_tokens)
    return inter / union

def find_best_hafs_match_in_sura(hafs_items_in_sura: List[Dict], warsh_item: Dict) -> Optional[Dict]:
    """
    العثور على أفضل آية مطابقة من حفص لآية ورش داخل نفس السورة اعتمادًا على التشابه النصي.
    """
    best = None
    best_score = -1.0
    w_text = warsh_item.get('aya_text', '')
    for h in hafs_items_in_sura:
        score = verse_similarity(h.get('aya_text', ''), w_text)
        # منح أولوية طفيفة لمطابقة رقم الآية إذا كان قريبًا (فرق <= 2)
        try:
            h_no = int(h.get('aya', h.get('aya_no', -100)))
            w_no = int(warsh_item.get('aya', warsh_item.get('aya_no', -100)))
            if h_no != -100 and w_no != -100 and abs(h_no - w_no) <= 2:
                score += 0.05
        except Exception:
            pass
        if score > best_score:
            best_score = score
            best = h
    # عتبة معقولة لضمان مطابقة حقيقية
    if best_score >= 0.05:
        return best
    #Fallback: نفس رقم الآية أو الأقرب
    try:
        w_no = int(warsh_item.get('aya', warsh_item.get('aya_no', -100)))
        candidates = []
        for h in hafs_items_in_sura:
            h_no = int(h.get('aya', h.get('aya_no', -100)))
            if h_no != -100:
                candidates.append((abs(h_no - w_no), h))
        if candidates:
            candidates.sort(key=lambda x: x[0])
            return candidates[0][1]
    except Exception:
        pass
    return None

def apply_newlines_to_text(text, newline_positions):
    """
    تطبيق \n على النص في المواضع المحددة
    newline_positions: قائمة بأرقام الكلمات التي يأتي بعدها \n
    """
    if not newline_positions:
        return text
    
    # تقسيم النص إلى كلمات (عدم إزالة رقم الآية)
    words = text.strip().split()
    
    # إضافة \n في المواضع المحددة
    result_parts = []
    last_pos = 0
    
    for pos in sorted(newline_positions):
        if pos <= len(words):
            # أخذ الكلمات من آخر موضع حتى الموضع الحالي
            part = ' '.join(words[last_pos:pos])
            result_parts.append(part)
            last_pos = pos
    
    # إضافة الكلمات المتبقية
    if last_pos < len(words):
        part = ' '.join(words[last_pos:])
        result_parts.append(part)
    
    # دمج الأجزاء مع \n
    result = '\n'.join(result_parts)
    
    return result

def main():
    parser = argparse.ArgumentParser(description='نقل \n من حفص إلى ورش')
    parser.add_argument('--sura', type=int, help='رقم السورة للمطابقة المستهدفة')
    parser.add_argument('--warsh-aya', type=int, help='رقم آية ورش المستهدفة')
    parser.add_argument('--hafs-aya', type=int, help='رقم آية حفص المصدر')
    args = parser.parse_args()
    # قراءة الملفات
    print("جاري قراءة الملفات...")
    
    with open('/Users/hawazenmahmood/Documents/GitHub/quran_library/assets/jsons/quran_hafs.json', 'r', encoding='utf-8') as f:
        hafs_data = json.load(f)
    
    with open('/Users/hawazenmahmood/Documents/GitHub/quran_library/assets/jsons/warshData_v2-1.json', 'r', encoding='utf-8') as f:
        warsh_data = json.load(f)
    
    print(f"عدد الآيات في quran_hafs: {len(hafs_data)}")
    print(f"عدد الآيات في warshData_v2-1: {len(warsh_data)}")
    
    # تجميع آيات حفص وورش حسب السورة
    hafs_by_sura = {}
    for item in hafs_data:
        s = item.get('sura_no')
        if s is not None:
            hafs_by_sura.setdefault(s, []).append(item)
    warsh_by_sura = {}
    for item in warsh_data:
        s = item.get('sura_no')
        if s is not None:
            warsh_by_sura.setdefault(s, []).append(item)
    
    # معالجة كل آية
    modified_count = 0
    # نمط مستهدف: نقل لآية محددة
    if args.sura and args.warsh_aya and args.hafs_aya:
        s = args.sura
        warsh_items = [w for w in warsh_by_sura.get(s, []) if parse_ayah_number(w.get('aya_no')) == args.warsh_aya]
        hafs_items = [h for h in hafs_by_sura.get(s, []) if parse_ayah_number(h.get('aya_no')) == args.hafs_aya]
        if not warsh_items or not hafs_items:
            print('تحذير: لم يتم العثور على الآيات المحددة للمطابقة')
        else:
            warsh_item = warsh_items[0]
            best_hafs = hafs_items[0]
            hafs_text = best_hafs.get('aya_text', '')
            warsh_text = warsh_item.get('aya_text', '')
            newline_positions = get_word_positions_with_newlines(hafs_text)
            warsh_positions = map_positions_hafs_to_warsh(hafs_text, warsh_text, newline_positions)
            print(f"مواضع \n (حفص {args.hafs_aya}): {newline_positions}")
            print(f"مواضع مناظرة (ورش {args.warsh_aya}): {warsh_positions}")
            new_warsh_text = apply_newlines_to_text(warsh_text, warsh_positions)
            print('قبل:\n' + warsh_text)
            print('بعد:\n' + new_warsh_text)
            warsh_item['aya_text'] = new_warsh_text
            modified_count += 1
    else:
        # الآن نمر على ورش ونجد أفضل مطابقة من حفص لكل آية في نفس السورة
        for s, warsh_items in warsh_by_sura.items():
            hafs_items = hafs_by_sura.get(s, [])
            if not hafs_items:
                print(f"تحذير: لا توجد آيات حفص للسورة {s}")
                continue
            for warsh_item in warsh_items:
                best_hafs = find_best_hafs_match_in_sura(hafs_items, warsh_item)
                if best_hafs is None:
                    info = f"sura={s}, aya={warsh_item.get('aya', warsh_item.get('aya_no','?'))}"
                    print(f"تحذير: لم يتم العثور على مطابقة قوية لورش ({info})")
                    continue

                hafs_text = best_hafs.get('aya_text', '')
                warsh_text = warsh_item.get('aya_text', '')
                # إيجاد مواضع \n في نص حفص (حسب الكلمات)
                newline_positions = get_word_positions_with_newlines(hafs_text)

                if newline_positions:
                    warsh_positions = map_positions_hafs_to_warsh(hafs_text, warsh_text, newline_positions)
                    new_warsh_text = apply_newlines_to_text(warsh_text, warsh_positions)
                    warsh_item['aya_text'] = new_warsh_text
                    modified_count += 1
                    if modified_count <= 5:
                        info = f"sura={s}, warsh_aya={warsh_item.get('aya', warsh_item.get('aya_no','?'))}, hafs_aya={best_hafs.get('aya', best_hafs.get('aya_no','?'))}"
                        print(f"\nمثال {modified_count} - {info}:")
                        print(f"  Hafs: {hafs_text[:100]}...")
                        print(f"  مواضع \\n (حفص): {newline_positions}")
                        print(f"  مواضع مناظرة (ورش): {warsh_positions}")
                        print(f"  Warsh قبل: {warsh_text[:100]}...")
                        print(f"  Warsh بعد: {new_warsh_text[:100]}...")
    
    print(f"\n✓ تم تعديل {modified_count} آية")
    
    # حفظ الملف المحدث
    output_path = '/Users/hawazenmahmood/Documents/GitHub/quran_library/assets/jsons/warshData_v2-1.json'
    print(f"\nجاري حفظ الملف المحدث...")
    
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(warsh_data, f, ensure_ascii=False, indent='\t')
    
    print(f"✓ تم حفظ الملف بنجاح: {output_path}")

if __name__ == '__main__':
    main()
