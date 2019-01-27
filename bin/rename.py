from os import rename, listdir, chdir, mkdir
from shutil import move, copy
import random

# need to update for different filetypes
def rename_files(directory):
    try:
        chdir('../data/' + directory)
    except FileExistsError as e:
        print(e)

    for filename in listdir('.'):
        file = filename.split('_')
        for part in file:
            # image name/number
            if 'img' in part: 
                name = part
            # file extension
            elif '.' in part:
                filetype = part
 
        # add exception handling 
        if filename.endswith('_UL' + filetype):
            rename(filename, '0_' + name + filetype)

        elif filename.endswith('_LL' + filetype):
            rename(filename, '1_' + name + filetype)

        elif filename.endswith('_UR' + filetype):
            rename(filename, '2_' + name + filetype)

        elif filename.endswith('_LR' + filetype):
            rename(filename, '3_' + name + filetype)

    try:
        chdir('../../bin/')
    except FileExistsError as e:
        print(e)


# move files from the new directory to either positive or negative
def move_files(directory):
    try:
        chdir('../data/' + directory)
    except FileExistsError as e:
        print(e)

    for filename in listdir('.'):
        # 0 or 1 glasses of wine => sober
        if filename.startswith('0') or filename.startswith('1'):
            try:
                move('./' + filename, '../negatives/' + filename)
            except FileNotFoundError as e:
                print(e)
        # else 2 or 3 glasses of wine => drunk
        else:
            try:
                move('./' + filename, '../positives/' + filename)
            except FileNotFoundError as e:
                print(e)
    
    try:
        chdir('../../bin/')
    except FileExistsError as e:
        print(e)


# move a random subset of images. puts extracted samples in new_directory
def extract_random_samples(directory, num_samples):
    try:
        chdir('../data/')
        mkdir('new_' + directory)
        chdir(directory)
    except FileExistsError as e:
        print(e)

    count = 0

    for filename in listdir('.'):
        if random.randint(0, 100) < 50 and num_samples > 0:
            copy('./' + filename, '../new_' + directory + '/' + filename)
            num_samples = num_samples - 1
            count = count + 1 

    print(str(count) + ' files were transferred over to new_' + directory)

    try:
        chdir('../../bin/')
    except FileExistsError as e:
        print(e)



if __name__ == '__main__':
    rename_files('')
    # move_files(dir)
    extract_random_samples('negatives', 100)
