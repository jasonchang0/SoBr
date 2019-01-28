import cv2
import os
import glob

os.chdir('../data/wine_project_files')

count = 1
for file in glob.glob('*webp'):
    if file.replace('.webp', '') == 'd4a7a2_6a981a4274584841b4d410babbf7f78f':
        continue

    img = cv2.imread(file, cv2.IMREAD_COLOR)
    h, w = img.shape[:2]

    UL = img[:h//2, :w//2]
    UR = img[:h//2, w//2:]
    LL = img[h//2:, :w//2]
    LR = img[h//2:, w//2:]

    cv2.imwrite('../ROI/img{}_UL.png'.format(count), UL)
    cv2.imwrite('../ROI/img{}_UR.png'.format(count), UR)
    cv2.imwrite('../ROI/img{}_LL.png'.format(count), LL)
    cv2.imwrite('../ROI/img{}_LR.png'.format(count), LR)

    count += 1

