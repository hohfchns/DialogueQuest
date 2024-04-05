#!/bin/bash

if [ "$(basename "$(pwd)")" == "docs" ]; then
  USER_DIR="./user"
  DEV_DIR="./developer"
else
  USER_DIR="./docs/user"
  DEV_DIR="./docs/developer"
fi

pandoc \
  -o ${USER_DIR}/../user_manual.pdf \
  \
  --listings -H ${USER_DIR}/../pandoc_setup.tex \
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
  ${USER_DIR}/statements/exit.md  \
  \
  -V 'fontfamily:dejavu'\
  -V colorlinks=true \
  -V linkcolor=blue \
  -V urlcolor=blue \
  -V toccolor=gray \

pandoc \
  -o ${DEV_DIR}/../developer_manual.pdf \
  \
  --listings -H ${DEV_DIR}/../pandoc_setup.tex \
  --toc \
  \
  ${DEV_DIR}/index.md \
  ${DEV_DIR}/../dialogue_quest_tester.md \
  ${DEV_DIR}/setup.md \
  ${DEV_DIR}/basics/examples.md \
  ${DEV_DIR}/basics/writing_dialogue.md \
  ${DEV_DIR}/basics/creating_characters.md \
  ${DEV_DIR}/basics/creating_dialogue.md \
  ${DEV_DIR}/basics/playing_dialogue.md \
  ${DEV_DIR}/basics/settings.md \
  ${DEV_DIR}/extending/extending_dialogue_quest.md \
  ${DEV_DIR}/extending/theming.md \
  ${DEV_DIR}/extending/custom_statements.md \
  ${DEV_DIR}/extending/custom_logic.md \
  ${DEV_DIR}/systems/flags.md \
  ${DEV_DIR}/systems/signals.md \
  \
  -V 'fontfamily:dejavu'\
  -V colorlinks=true \
  -V linkcolor=blue \
  -V urlcolor=blue \
  -V toccolor=gray \

