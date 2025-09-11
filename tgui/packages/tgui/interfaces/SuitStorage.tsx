import {
  Box,
  Button,
  Divider,
  LabeledList,
  NoticeBox,
  Section,
  Stack,
} from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';

interface SuitStorageData {
  panelOpen: boolean;
  isUV: boolean;
  isOpen: boolean;
  locked: boolean;
  issuperUV: boolean;
  safeties: boolean;
  hasOccupant: boolean;
  helmet: string | null;
  suit: string | null;
  mask: string | null;
}

export const SuitStorage = () => {
  const { act, data } = useBackend<SuitStorageData>();
  const {
    panelOpen,
    isUV,
    isOpen,
    locked,
    issuperUV,
    safeties,
    hasOccupant,
    helmet,
    suit,
    mask,
  } = data;

  if (panelOpen) {
    return (
      <Window width={400} height={300}>
        <Window.Content>
          <Section title="Maintenance Panel Controls">
            <Stack vertical>
              <Stack.Item>
                <Box mb={2}>
                  A small dial with a small lambda symbol on it. It&apos;s
                  pointing towards a gauge that reads{' '}
                  <Box as="span" bold>
                    {issuperUV ? '15nm' : '185nm'}
                  </Box>
                  .
                </Box>
                <Button
                  content={`Turn towards ${issuperUV ? '185nm' : '15nm'}`}
                  onClick={() => act('toggleUV')}
                  mb={2}
                />
              </Stack.Item>

              <Stack.Item>
                <Box mb={2}>
                  A thick old-style button, with 2 grimy LED lights next to it.
                  The{' '}
                  <Box as="span" bold color={safeties ? 'green' : 'red'}>
                    {safeties ? 'GREEN' : 'RED'}
                  </Box>{' '}
                  LED is on.
                </Box>
                <Button
                  content="Press button"
                  onClick={() => act('togglesafeties')}
                />
              </Stack.Item>
            </Stack>
          </Section>
        </Window.Content>
      </Window>
    );
  }

  if (isUV) {
    return (
      <Window width={400} height={200}>
        <Window.Content>
          <Section title="Suit Storage Unit">
            <NoticeBox color="red">
              <Box bold>
                Unit is cauterising contents with selected UV ray intensity.
                Please wait.
              </Box>
            </NoticeBox>
          </Section>
        </Window.Content>
      </Window>
    );
  }

  return (
    <Window width={400} height={500}>
      <Window.Content>
        <Section title="Suit Storage Unit">
          <Stack vertical>
            <Stack.Item>
              <LabeledList>
                <LabeledList.Item label="Helmet storage compartment">
                  <Box color={helmet ? 'default' : 'grey'}>
                    {helmet || 'No helmet detected.'}
                  </Box>
                  {helmet && isOpen && (
                    <Button
                      content="Dispense helmet"
                      onClick={() => act('dispense_helmet')}
                      mt={1}
                    />
                  )}
                </LabeledList.Item>

                <LabeledList.Item label="Suit storage compartment">
                  <Box color={suit ? 'default' : 'grey'}>
                    {suit || 'No exosuit detected.'}
                  </Box>
                  {suit && isOpen && (
                    <Button
                      content="Dispense suit"
                      onClick={() => act('dispense_suit')}
                      mt={1}
                    />
                  )}
                </LabeledList.Item>

                <LabeledList.Item label="Breathmask storage compartment">
                  <Box color={mask ? 'default' : 'grey'}>
                    {mask || 'No breathmask detected.'}
                  </Box>
                  {mask && isOpen && (
                    <Button
                      content="Dispense mask"
                      onClick={() => act('dispense_mask')}
                      mt={1}
                    />
                  )}
                </LabeledList.Item>
              </LabeledList>
            </Stack.Item>

            {hasOccupant && (
              <Stack.Item>
                <Divider />
                <NoticeBox color="red">
                  <Box bold>
                    WARNING: Biological entity detected inside the Unit&apos;s
                    storage. Please remove.
                  </Box>
                </NoticeBox>
                <Button
                  content="Eject extra load"
                  onClick={() => act('eject_guy')}
                  mt={1}
                />
              </Stack.Item>
            )}

            <Stack.Item>
              <Divider />
              <LabeledList>
                <LabeledList.Item label="Unit is">
                  <Box inline mr={2}>
                    {isOpen ? 'Open' : 'Closed'}
                  </Box>
                  <Button
                    content={isOpen ? 'Close Unit' : 'Open Unit'}
                    onClick={() => act('toggle_open')}
                  />
                  {!isOpen && (
                    <Button
                      content={locked ? 'Unlock Unit' : 'Lock Unit'}
                      onClick={() => act('toggle_lock')}
                      color="orange"
                      ml={1}
                    />
                  )}
                </LabeledList.Item>

                <LabeledList.Item label="Unit status">
                  <Box bold color={locked ? 'red' : 'green'}>
                    {locked ? '**LOCKED**' : '**UNLOCKED**'}
                  </Box>
                </LabeledList.Item>
              </LabeledList>

              <Button
                content="Start Disinfection cycle"
                onClick={() => act('start_UV')}
                mt={2}
              />
            </Stack.Item>
          </Stack>
        </Section>
      </Window.Content>
    </Window>
  );
};
