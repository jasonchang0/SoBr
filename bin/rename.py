from os import rename, listdir, chdir
from shutil import move

def rename_files(directory, filetype):

    chdir('../data/' + directory)
    for filename in listdir('.'):
        
        if filename.endswith('_UL' + filetype):
            rename(filename, '0_' + filename.split('_')[0] + filetype)

        elif filename.endswith('_LL' + filetype):
            rename(filename, '1_' + filename.split('_')[0] + filetype)

        elif filename.endswith('_UR' + filetype):
            rename(filename, '2_' + filename.split('_')[0] + filetype)

        elif filename.endswith('_LR' + filetype):
            rename(filename, '3_' + filename.split('_')[0] + filetype)


def move_files():
    chdir('../data/')
    for filename in listdir('.'):
        
        if filename.startswith('0') or filename.startswith('1'):
            move('./' + filename, './negatives/' + filename)
        else:
            move('./' + filename, './positives/' + filename)
            

if __name__ == '__main__':
    rename_files('resize_frontal_faces', '.png')
    move_files()
