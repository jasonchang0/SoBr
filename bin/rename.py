from os import rename, listdir, chdir
from shutil import move

def rename_files(directory, filetype):
    chdir('../data/' + directory)

    for filename in listdir('.'):

        # Find name (img#) and set it as the name of the file
        file = filename.split('_')
        for part in file:
            if 'img' in part: 
                name = part
                break
 
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


if __name__ == '__main__':
    dir = input("Enter repository name: ")
    filetype = input("Enter file type (png, jpeg, etc): ")

    # rename_files('negatives', '.jpeg')
    rename_files('resize_frontal_face', '.png')
    # rename_files(dir, filetype)
    move_files('resize_frontal_face')
