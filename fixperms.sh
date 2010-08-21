#!/bin/bash

# fuct up experimental hack -- is it stupid to try to have different users be committing to the same working copy repo? 

find .git -type d | while read -r line; do sudo chgrp roxanne-group $line; sudo chmod g+w $line; sudo chmod g+x $line; done
find .git -type f | while read -r line; do sudo chgrp roxanne-group $line; sudo chmod g+w $line; done

