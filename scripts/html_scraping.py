import re
import os
# import image_scraper
from google_images_download import google_images_download   # importing the library

os.chdir('../data')

with open('wine_project_html.txt', 'r') as file:
    data = file.read().replace('\n', '')

data_lst = data.split('\"')

imgs_url = set()

for _ in data_lst:
    if '#image_' in _:
        imgs_url.add(_[1:])

print(imgs_url)
print(len(imgs_url))

prefix = 'https://www.masmorrastudio.com/wine-project?lightbox='

for url in imgs_url:
    # image_scraper.scrape_images(prefix + url)

    # class instantiation
    response = google_images_download.googleimagesdownload()

    # creating list of arguments
    arguments = {'url': prefix + url, 'format': 'webp',
                 'print_urls': True, 'usage_rights': 'labeled-for-nocommercial-reuse'}

    # passing the arguments to the function
    paths = response.download(arguments)

    # printing absolute paths of the downloaded images
    print(paths)

