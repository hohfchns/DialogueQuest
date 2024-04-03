#!/bin/bash

if [ "$(basename "$(pwd)")" == "docs" ]; then
  USER_DIR="./user"
  DEV_DIR="./developer"
else
  USER_DIR="./docs/user"
  DEV_DIR="./docs/developer"
fi

pandoc \
  -o user_manual.pdf \
  \
  --listings -H pandoc_setup.tex \
  --toc \
  \
  ${USER_DIR}/index.md \
  ${USER_DIR}/../dialogue_quest_tester.md \
  ${USER_DIR}/writing_dialogue.md \
  ${USER_DIR}/characters.md \
  ${USER_DIR}/statements/say.md  \
  ${USER_DIR}/statements/flag.md  \
  ${USER_DIR}/statements/choice.md  \
  ${USER_DIR}/statements/branch.md  \
  ${USER_DIR}/statements/signal.md  \
  ${USER_DIR}/statements/call.md  \
  \
  -V 'fontfamily:dejavu'\
  -V colorlinks=true \
  -V linkcolor=blue \
  -V urlcolor=blue \
  -V toccolor=gray \

pandoc \
  -o developer_manual.pdf \
  \
  --listings -H pandoc_setup.tex \
  --toc \
  \
  ${DEV_DIR}/index.md \
  ${DEV_DIR}/../dialogue_quest_tester.md \
  ${DEV_DIR}/examples.md \
  ${DEV_DIR}/writing_dialogue.md \
  ${DEV_DIR}/creating_characters.md \
  ${DEV_DIR}/creating_dialogues.md \
  ${DEV_DIR}/extending_dialogue_quest.md \
  \
  -V 'fontfamily:dejavu'\
  -V colorlinks=true \
  -V linkcolor=blue \
  -V urlcolor=blue \
  -V toccolor=gray \

