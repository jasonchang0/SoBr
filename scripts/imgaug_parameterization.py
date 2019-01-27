import imgaug as ia
from imgaug import augmenters as iaa
import numpy as np
import cv2

img = cv2.imread('../data/resize_frontal_face/haar_img9_LR.png', cv2.IMREAD_COLOR)

img_aug = iaa.AdditiveGaussianNoise(scale=0.3*255).augment_image(img)
cv2.imshow('image', img_aug)

cv2.waitKey(0)
cv2.destroyAllWindows()
