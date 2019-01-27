import imgaug as ia
from imgaug import augmenters as iaa
import numpy as np
import cv2
import itertools
import os
import glob
from functools import reduce
import random

meta = {'noop': iaa.Noop(), 'shuffle': iaa.ChannelShuffle(p=1.0)}

arithmetic = {'add-45': iaa.Add(value=-45),
              'add-25': iaa.Add(value=-25), 'add+25': iaa.Add(value=25), 'add+45': iaa.Add(value=45),
              'addp-': iaa.Add(value=(-35, -15), per_channel=True), 'addp+': iaa.Add(value=(15, 35), per_channel=True),
              'addGN': iaa.AdditiveGaussianNoise(scale=0.10 * 255),
              'addGNp': iaa.AdditiveGaussianNoise(scale=0.10 * 255, per_channel=True),
              'addLN': iaa.AdditiveLaplaceNoise(scale=0.10 * 255),
              'addLNp': iaa.AdditiveLaplaceNoise(scale=0.10 * 255, per_channel=True),
              'addPN': iaa.AdditivePoissonNoise(lam=16.00),
              'addPNp': iaa.AdditivePoissonNoise(lam=16.00, per_channel=True),
              'mul-': iaa.Multiply(mul=0.50), 'mul+': iaa.Multiply(mul=1.50),
              'mulp-': iaa.Multiply(mul=0.50, per_channel=True), 'mulp+': iaa.Multiply(mul=1.50, per_channel=True),
              'jpeg': iaa.JpegCompression(compression=62), 'jpeg+': iaa.JpegCompression(compression=75),
              'jpeg++': iaa.JpegCompression(compression=87)}

blur = {'GBlur': iaa.GaussianBlur(sigma=1.00),
        'ABlur': iaa.AverageBlur(k=3), 'MBlur': iaa.MedianBlur(k=3),
        'BBlur': iaa.BilateralBlur(sigma_color=250, sigma_space=250, d=5),
        'MoBlur': iaa.MotionBlur(angle=0, k=7), 'MoBlurAng': iaa.MotionBlur(angle=144, k=5)}

color = {'ATHAS-': iaa.AddToHueAndSaturation(value=-45), 'ATHAS+': iaa.AddToHueAndSaturation(value=45),
         'Gray': iaa.Grayscale(alpha=0.2)}

contrast = {'GContrast-': iaa.GammaContrast(gamma=0.81),
            'GContrast+': iaa.GammaContrast(gamma=1.44), 'SContrast': iaa.SigmoidContrast(cutoff=0.5, gain=10),
            'LContrast': iaa.LogContrast(gain=0.88), 'LiContrast': iaa.LinearContrast(alpha=1.38)}

flip = {'flipLR': iaa.Fliplr(p=1.0)}

geometric = {'PAffine': iaa.PiecewiseAffine(scale=0.030), 'PTrans-': iaa.PerspectiveTransform(scale=0.50),
             'PTrans': iaa.PerspectiveTransform(scale=0.75), 'PTrans+': iaa.PerspectiveTransform(scale=1.0),
             'ETrans': iaa.ElasticTransformation(sigma=5.0, alpha=15.1)}

size = {'zoomOutU': iaa.PadToFixedSize(height=102, width=102, position='uniform'),
        'zoomOutN': iaa.PadToFixedSize(height=102, width=102, position='normal'),
        'zoomOutC': iaa.PadToFixedSize(height=102, width=102, position='center'),
        'zoomInU': iaa.PadToFixedSize(height=38, width=38, position='uniform'),
        'zoomInN': iaa.PadToFixedSize(height=38, width=38, position='normal'),
        'zoomInC': iaa.PadToFixedSize(height=38, width=38, position='center')}

weather = {'FSnowL': iaa.FastSnowyLandscape(lightness_multiplier=2.0, lightness_threshold=50),
           'Clouds': iaa.Clouds(), 'Fog': iaa.Fog(), 'SnowF': iaa.Snowflakes()}

effects = {**meta, **arithmetic, **blur, **color, **contrast, **flip, **geometric, **size, **weather}

print(effects.keys())
print(len(effects.keys()))

os.chdir('../data/resize_frontal_face')

count = 0

for i in range(2):
    # combs = [_ for _ in itertools.combinations(effects, i + 1)]
    combs = list(itertools.combinations(effects.keys(), i + 1))

    # Shuffles the array in-place
    # combs = random.shuffle(combs)
    combs = random.sample(combs, len(combs))

    print(len(combs))

    for aug in combs:

        if count > 50000:
            break

        aug_effects = list(map(lambda x: effects[x], aug))
        # print(str(aug_effects))

        if not len(aug_effects) - 1:
            seq = aug_effects[0].to_deterministic()

        else:
            seq = iaa.Sequential(aug_effects).to_deterministic()

        for file in glob.glob('haar*.png'):
            if len(file) > 17:
                continue

            print(i + 1, file, count)

            img = cv2.imread(file, cv2.IMREAD_COLOR)
            aug_img = seq.augment_image(img)

            ext = reduce((lambda x, y: str(x) + '_' + str(y)), aug)

            cv2.imwrite(file.replace('.png', '_{}.png'.format(ext)), aug_img)

            count += 1




