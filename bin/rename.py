from os import rename, listdir, chdir, mkdir
from shutil import move, copy
import random

def rename_files(directory, filetype):
    chdir('../data/' + directory)

    for filename in listdir('.'):

        # Find name (img#) and set it as the name of the file
        file = filename.split('_')
        for part in file:
            if 'img' in part: 
                name = part
                break
 
        # add exception handling 
        if filename.endswith('_UL' + filetype):
            rename(filename, '0_' + name + filetype)

        elif filename.endswith('_LL' + filetype):
            rename(filename, '1_' + name + filetype)

        elif filename.endswith('_UR' + filetype):
            rename(filename, '2_' + name + filetype)

        elif filename.endswith('_LR' + filetype):
            rename(filename, '3_' + name + filetype)

    chdir('../../bin/')


# move files from the new directory to either positive or negative
def move_files(directory):
    chdir('../data/' + directory)

    for filename in listdir('.'):
        
        if filename.startswith('0') or filename.startswith('1'):
            try:
                move('./' + filename, '../negatives/' + filename)
            except FileNotFoundError as e:
                print(e)
        else:
            try:
                move('./' + filename, '../positives/' + filename)
            except FileNotFoundError as e:
                print(e)

    chdir('../../bin/')


# move a random subset of images. puts extracted samples in new_directory
def extract_random_samples(directory, num_samples):
    chdir('../data/')
    try:
        mkdir('new_' + directory)
    except FileExistsError as e:
        print(e)

    chdir(directory)
    count = 0

    for filename in listdir('.'):
        if random.randint(0, 100) < 50 and num_samples > 0:
            copy('./' + filename, '../new_' + directory + '/' + filename)
            num_samples = num_samples - 1
            count = count + 1 

    print(str(count) + ' files were transferred over to new_' + directory)
    chdir('../../bin/')


if __name__ == '__main__':
    dir = input("Enter repository name: ")
    filetype = input("Enter file type (png, jpeg, etc): ")

    # rename_files(dir, filetype)
    # move_files(dir)
    extract_random_samples('negatives', 100)

