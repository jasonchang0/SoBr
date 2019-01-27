import cv2
import numpy as np
import os
import glob
import sys
import matplotlib.pyplot as plt
import matplotlib.style as style
from pathlib import Path

style.use('fivethirtyeight')

os.chdir('../data')

face_cascade = cv2.CascadeClassifier('haarcascade_frontalface_default.xml')

min_w = sys.maxsize
min_h = sys.maxsize

width = []
height = []

os.chdir('./ROI')

for file in sorted(glob.glob('*.png')):
    print(file)

    img = cv2.imread(file, cv2.IMREAD_COLOR)
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

    faces = face_cascade.detectMultiScale(gray, 1.01, 10)

    if not len(faces):
        if Path('../haar_frontal_face/error.txt').exists():
            open_file = open('../haar_frontal_face/error.txt', 'a')
        else:
            open_file = open('../haar_frontal_face/error.txt', 'w')

        open_file.write('{}\n'.format(file))
        open_file.close()

        continue

    x, y, w, h = faces[0]
    width += [w]
    height += [h]

    if faces[0, 3] < 105 or faces[0, 2] < 105:
        dir = 'min_frontal_face'

    else:
        dir = 'haar_frontal_face'

        if w < min_w:
            min_w = w

        if h < min_h:
            min_h = h

    face = img[y:y + h, x:x + w]

    cv2.imwrite('../{}/haar_{}'.format(dir, file), face)

print(min_w, min_h)


os.chdir('../haar_frontal_face')

for file in glob.glob('*.png'):
    print(file)

    img = cv2.imread(file, cv2.IMREAD_COLOR)
    img_shape = img.shape

    img = cv2.resize(img, (0, 0), fx=min_w / img_shape[1], fy=min_h / img_shape[0], interpolation=cv2.INTER_AREA)

    cv2.imwrite('../resize_frontal_face/{}'.format(file), img)

print(height)

plt.hist(height, density=True)
plt.title('Height Histogram')

plt.xlabel('Value')
plt.ylabel('Frequency')

plt.show()

