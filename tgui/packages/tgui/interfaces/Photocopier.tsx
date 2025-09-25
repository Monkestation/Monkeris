import {
  Box,
  Button,
  Flex,
  LabeledList,
  NoticeBox,
  Section,
  Stack,
} from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';

interface PhotocopierData {
  hasCopyitem: boolean;
  toner: number;
  copies: number;
  isSilicon: boolean;
}

export const Photocopier = () => {
  const { act, data } = useBackend<PhotocopierData>();
  const { hasCopyitem, toner, copies, isSilicon } = data;

  return (
    <Window width={400} height={350}>
      <Window.Content>
        <Section title="Photocopier">
          <Stack vertical>
            {hasCopyitem ? (
              <Stack.Item>
                <Button
                  content="Remove Item"
                  onClick={() => act('remove')}
                  mb={2}
                />

                {toner > 0 && (
                  <>
                    <Button content="Copy" onClick={() => act('copy')} mb={2} />

                    <Flex align="center" mb={2}>
                      <Flex.Item>
                        <Box mr={2}>Printing: {copies} copies.</Box>
                      </Flex.Item>
                      <Flex.Item>
                        <Button content="-" onClick={() => act('min')} mr={1} />
                        <Button content="+" onClick={() => act('add')} />
                      </Flex.Item>
                    </Flex>
                  </>
                )}
              </Stack.Item>
            ) : (
              toner > 0 && (
                <Stack.Item>
                  <Box mb={2}>Please insert something to copy.</Box>
                </Stack.Item>
              )
            )}

            {isSilicon && (
              <Stack.Item>
                <Button
                  content="Print photo from database"
                  onClick={() => act('aipic')}
                  mb={2}
                />
              </Stack.Item>
            )}

            <Stack.Item>
              <LabeledList>
                <LabeledList.Item label="Current toner level">
                  <Box color={toner > 0 ? 'default' : 'red'}>{toner}</Box>
                </LabeledList.Item>
              </LabeledList>

              {toner === 0 && (
                <NoticeBox color="red" mt={1}>
                  Please insert a new toner cartridge!
                </NoticeBox>
              )}
            </Stack.Item>
          </Stack>
        </Section>
      </Window.Content>
    </Window>
  );
};
