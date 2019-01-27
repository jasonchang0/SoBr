from keras.preprocessing.image import ImageDataGenerator
from keras.models import Sequential
from sklearn.model_selection import train_test_split
from keras.layers import Dense, Dropout, Flatten
from keras.layers import Conv2D, MaxPooling2D
from keras.callbacks import TensorBoard
from keras import optimizers
from skimage import io
from skimage.transform import resize
from keras.utils import to_categorical
import numpy as np
import tensorflow as tf
import random
import glob
import coremltools

random_seed = 1

tf.set_random_seed(random_seed)
np.random.seed(random_seed)

batch_size = 32
num_classes = 2
epochs = 80
log_filepath = './deepKerasLog'

nCategorySamples = 4000
positiveSamples = glob.glob('workspace/SoBr/data/resize_frontal_face/yes/*')[0:nCategorySamples]
negativeSamples = glob.glob('workspace/SoBr/data/resize_frontal_face/no/*')[0:nCategorySamples]

nImageRows = 106
nImageCols = 106
nChannels = 3

negativeSamples = random.sample(negativeSamples, len(positiveSamples))
X_train = []
Y_train = []
for i in range(len(positiveSamples)):
    X_train.append(resize(io.imread(positiveSamples[i]), (nImageRows, nImageCols)))
    Y_train.append(1)
    if i % 1000 == 0:
        print('Reading positive image number ', i)
for i in range(len(negativeSamples)):
    X_train.append(resize(io.imread(negativeSamples[i]), (nImageRows, nImageCols)))
    Y_train.append(0)
    if i % 1000 == 0:
        print('Reading negative image number ', i)

X_train = np.array(X_train)
Y_train = np.array(Y_train)

X_train, X_test, Y_train, Y_test = train_test_split(X_train, Y_train, test_size=0.30, random_state=42)

mean  = X_train.mean(axis=0).mean(axis=0).mean(axis=0)
#std   = X_train.std(axis=0).mean(axis=0).mean(axis=0)
mean = np.array([0.5,0.5,0.5])
std = np.array([1,1,1])
X_train = X_train.astype('float')
X_test = X_test.astype('float')
for i in range(3):
    X_train[:,:,:,i] = (X_train[:,:,:,i]- mean[i]) / std[i]
    X_test[:,:,:,i] = (X_test[:,:,:,i]- mean[i]) / std[i]

num_iterations = int(len(X_train)/batch_size) + 1

Y_train = to_categorical(Y_train, num_classes)
Y_test = to_categorical(Y_test, num_classes)

modelInputShape = (nImageRows, nImageCols, nChannels)
model = Sequential()
model.add(Conv2D(8,kernel_size=(3,3), activation='relu', strides=(1,1), padding='same', input_shape=modelInputShape))
model.add(MaxPooling2D(pool_size=(2,2), strides=(2,2), padding='valid'))
model.add(Dropout(0.25))
model.add(Conv2D(16,kernel_size=(3,3), padding='same', activation='relu'))
model.add(MaxPooling2D(pool_size=(2,2), strides=(2,2), padding='valid'))
model.add(Dropout(0.25))
model.add(Conv2D(16,kernel_size=(3,3), padding='same', activation='relu'))
model.add(MaxPooling2D(pool_size=(2,2), strides=(2,2), padding='valid'))
model.add(Conv2D(8,kernel_size=(3,3), padding='same', activation='relu'))
model.add(MaxPooling2D(pool_size=(2,2), strides=(2,2), padding='valid'))
#model.add(Conv2D(8,kernel_size=(3,3), padding='same', activation='relu'))
#model.add(MaxPooling2D(pool_size=(2,2), strides=(2,2), padding='valid'))


model.add(Flatten())
model.add(Dense(10, activation='relu'))
model.add(Dense(2, activation='softmax'))

sgd = optimizers.SGD(lr=.001, momentum=0.9, decay=0.000005, nesterov=False)
model.compile(loss='categorical_crossentropy', optimizer=sgd, metrics=['accuracy'])

print(model.summary())

#datagen = ImageDataGenerator(
#    featurewise_center=True,
#    featurewise_std_normalization=True,
#    rotation_range=0,
#    width_shift_range=0.05,
#    height_shift_range=0.07,
#    zoom_range=0.05,
#    horizontal_flip=True)
#datagen.fit(X_train)


tensorBoardCallback = TensorBoard(log_dir=log_filepath, histogram_freq=0)
callbacks = [tensorBoardCallback]

model.fit(X_train, Y_train, batch_size=batch_size, epochs=epochs, validation_data=(X_test,Y_test))
#model.fit_generator(datagen.flow(X_train, Y_train,batch_size=batch_size),
#        steps_per_epoch=1*num_iterations,
#        epochs=epochs,
#        callbacks=callbacks,
#        validation_data=(X_test, Y_test))

score=model.evaluate(X_test, Y_test, verbose=0)


print('Test loss: ', score[0])
print('Test accuracy: ', score[1])

coreml_model = coremltools.converters.keras.convert(model, 
                                                    input_names=['image'], 
                                                    output_names=['output'], 
                                                    class_labels=['Negative', 'Drunk'],
                                                    image_input_names='image', 
                                                    image_scale=1/255.0, 
                                                    red_bias=-0.5,
                                                    green_bias=-0.5, 
                                                    blue_bias=-0.5)

coreml_model.save('DrunkKerasModel.mlmodel')
