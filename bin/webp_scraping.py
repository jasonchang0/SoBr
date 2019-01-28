import re
import os
import glob
import image_scraper
from google_images_download import google_images_download  # importing the library

os.chdir('../data/wine_project_files')

imgs_url = []

for file in glob.glob('*.jpg'):
    imgs_url += [file.replace('.jpg', '')]

print(imgs_url)
print(len(imgs_url))

'''
https://static.wixstatic.com/media/d4a7a2_1fecc1f8206b4de0ad9baafc055eee83.jpg/v1/fill/w_1000,h_1000,al_c,q_90/d4a7a2_1fecc1f8206b4de0ad9baafc055eee83.webp
'''

prefix = 'https://static.wixstatic.com/media/{}.jpg/v1/fill/w_1000,h_1000,al_c,q_90/{}.webp'

for url in imgs_url:
    image_scraper.scrape_images(prefix.format(url, url))

    '''
    # class instantiation
    response = google_images_download.googleimagesdownload()

    # creating list of arguments
    arguments = {'url': prefix.format(url, url), 'format': 'webp',
                 'print_urls': True, 'usage_rights': 'labeled-for-nocommercial-reuse'}

    # passing the arguments to the function
    paths = response.download(arguments)

    # printing absolute paths of the downloaded images
    print(paths)
    '''


