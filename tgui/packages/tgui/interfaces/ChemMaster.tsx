import { useState } from 'react';
import {
  Box,
  Button,
  Flex,
  NoticeBox,
  Section,
  Stack,
} from 'tgui-core/components';
import { BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { Window } from '../layouts';

interface Reagent {
  name: string;
  id: string;
  volume: number;
  description: string;
}

interface ChemMasterData {
  condi: BooleanLike;
  mode: BooleanLike;
  hasBeaker: BooleanLike;
  useramount: number;
  pillamount: number;
  pillsprite: string;
  bottlesprite: string;
  maxPillCount: number;
  maxPillVol: number;
  beakerVolume?: number;
  beakerMaxVolume?: number;
  beakerReagents?: Reagent[];
  bufferVolume: number;
  bufferMaxVolume: number;
  bufferFreeSpace: number;
  bufferReagents: Reagent[];
}

interface ReagentControlsProps {
  reagent: Reagent;
  isBeaker: BooleanLike;
}

export const ChemMaster = () => {
  const { act, data } = useBackend<ChemMasterData>();
  const [customAmount, setCustomAmount] = useState('30');

  const {
    condi,
    mode,
    hasBeaker,
    beakerReagents = [],
    bufferReagents = [],
    bufferFreeSpace,
    bufferVolume,
    maxPillCount,
    maxPillVol,
  } = data;

  const title = condi ? 'CondiMaster 3000' : 'ChemMaster 3000';

  const ReagentControls = ({ reagent, isBeaker }: ReagentControlsProps) => (
    <Flex align="center" mb={1}>
      <Flex.Item grow>
        <Box>
          {reagent.name}, {reagent.volume} Units
        </Box>
      </Flex.Item>
      <Flex.Item>
        <Button
          content="Analyze"
          onClick={() =>
            act('analyze', {
              name: reagent.name,
              desc: reagent.description,
            })
          }
          mr={1}
        />
        {isBeaker ? (
          // Beaker reagent controls (Add to buffer)
          <>
            {[1, 5, 10].map((amount) => (
              <Button
                key={amount}
                content={`${amount}`}
                disabled={bufferFreeSpace < amount}
                onClick={() =>
                  act('add', {
                    id: reagent.id,
                    amount: amount,
                  })
                }
                mr={0.5}
              />
            ))}
            <Button
              content="All"
              onClick={() =>
                act('add', {
                  id: reagent.id,
                  amount: reagent.volume,
                })
              }
              mr={0.5}
            />
            <Button
              content="Custom"
              onClick={() => act('addcustom', { id: reagent.id })}
            />
          </>
        ) : (
          // Buffer reagent controls (Remove/Transfer)
          <>
            {[1, 5, 10].map((amount) => (
              <Button
                key={amount}
                content={`${amount}`}
                onClick={() =>
                  act('remove', {
                    id: reagent.id,
                    amount: amount,
                  })
                }
                mr={0.5}
              />
            ))}
            <Button
              content="All"
              onClick={() =>
                act('remove', {
                  id: reagent.id,
                  amount: reagent.volume,
                })
              }
              mr={0.5}
            />
            <Button
              content="Custom"
              onClick={() => act('removecustom', { id: reagent.id })}
            />
          </>
        )}
      </Flex.Item>
    </Flex>
  );

  return (
    <Window width={600} height={700}>
      <Window.Content scrollable>
        <Stack vertical>
          {!hasBeaker ? (
            <Stack.Item>
              <NoticeBox>Please insert beaker.</NoticeBox>
            </Stack.Item>
          ) : (
            <>
              <Stack.Item>
                <Section title="Beaker Controls">
                  <Button
                    content="Eject beaker and Clear Buffer"
                    onClick={() => act('eject')}
                    mb={2}
                  />

                  {beakerReagents.length === 0 ? (
                    <Box>Beaker is empty.</Box>
                  ) : (
                    <>
                      <Box mb={2}>Add to buffer:</Box>
                      {beakerReagents.map((reagent, index) => (
                        <ReagentControls
                          key={index}
                          reagent={reagent}
                          isBeaker
                        />
                      ))}
                      {bufferFreeSpace < 1 && (
                        <NoticeBox color="red">The {title} is full!</NoticeBox>
                      )}
                    </>
                  )}
                </Section>
              </Stack.Item>

              <Stack.Item>
                <Section
                  title={
                    <>
                      Transfer to{' '}
                      <Button
                        content={mode ? 'beaker' : 'disposal'}
                        onClick={() => act('toggle')}
                        color={mode ? 'good' : 'average'}
                      />
                    </>
                  }
                >
                  {bufferReagents.length === 0 ? (
                    <Box>Empty</Box>
                  ) : (
                    bufferReagents.map((reagent, index) => (
                      <ReagentControls
                        key={index}
                        reagent={reagent}
                        isBeaker={false}
                      />
                    ))
                  )}
                </Section>
              </Stack.Item>

              <Stack.Item>
                <Section title="Create Items">
                  {!condi ? (
                    <Stack vertical>
                      <Stack.Item>
                        <Flex align="center">
                          <Flex.Item>
                            <Button
                              content={`Create pill (${maxPillVol} units max)`}
                              onClick={() => act('createpill')}
                              disabled={bufferVolume === 0}
                            />
                          </Flex.Item>
                          <Flex.Item ml={1}>
                            <Button
                              content="Change Style"
                              onClick={() => act('change_pill')}
                            />
                          </Flex.Item>
                        </Flex>
                      </Stack.Item>
                      <Stack.Item>
                        <Button
                          content="Create multiple pills"
                          onClick={() => act('createpill_multiple')}
                          disabled={bufferVolume === 0}
                        />
                      </Stack.Item>
                      <Stack.Item>
                        <Flex align="center">
                          <Flex.Item>
                            <Button
                              content="Create bottle (60 units max)"
                              onClick={() => act('createbottle')}
                              disabled={bufferVolume === 0}
                            />
                          </Flex.Item>
                          <Flex.Item ml={1}>
                            <Button
                              content="Change Style"
                              onClick={() => act('change_bottle')}
                            />
                          </Flex.Item>
                        </Flex>
                      </Stack.Item>
                    </Stack>
                  ) : (
                    <Button
                      content="Create bottle (50 units max)"
                      onClick={() => act('createbottle')}
                      disabled={bufferVolume === 0}
                    />
                  )}
                </Section>
              </Stack.Item>
            </>
          )}
        </Stack>
      </Window.Content>
    </Window>
  );
};
