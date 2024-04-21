from setuptools import setup, find_packages

setup(
    name='goldenpond',
    version='0.2.0',
    packages=find_packages(),
    description="""
GoldenPond is a little language for defining musical chord progressions in terms of 'functional harmony'.

The goal is to help code-based musicians understand music theory better and to give, particularly live-coders, a more expressive way to represent complex chord progressions and various decorations from them such as arpeggiation, basslines etc  
"""
    ,
    long_description=open('README.md').read(),
    long_description_content_type='text/markdown',
    author='Phil Jones (Mentufacturer)',
    author_email='interstar@gmail.com',
    url='https://github.com/interstar/golden-pond',
    install_requires=[
        
    ],
    classifiers=[
        'Programming Language :: Python :: 3',
        'License :: OSI Approved :: GNU Lesser General Public License v3 (LGPLv3)',
        'Operating System :: OS Independent',
    ],
)

