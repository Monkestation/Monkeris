import {
  Box,
  Button,
  LabeledList,
  NoticeBox,
  Section,
  Stack,
} from 'tgui-core/components';
import { BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { Window } from '../layouts';

interface LawData {
  index: number;
  law: string;
}

interface AIFixerData {
  hasOccupant: BooleanLike;
  active: BooleanLike;
  aiName?: string;
  hardwareIntegrity?: number;
  backupCapacitor?: number;
  aiDead?: BooleanLike;
  laws?: LawData[];
}

export const AIFixer = () => {
  const { act, data } = useBackend<AIFixerData>();
  const {
    hasOccupant,
    active,
    aiName,
    hardwareIntegrity,
    backupCapacitor,
    aiDead,
    laws = [],
  } = data;

  return (
    <Window width={400} height={500}>
      <Window.Content>
        <Section title="AI System Integrity Restorer">
          <Stack vertical>
            {hasOccupant ? (
              <>
                <Stack.Item>
                  <LabeledList>
                    <LabeledList.Item label="Stored AI">
                      {aiName}
                    </LabeledList.Item>
                    <LabeledList.Item label="System integrity">
                      {hardwareIntegrity}%
                    </LabeledList.Item>
                    <LabeledList.Item label="Backup Capacitor">
                      {backupCapacitor}%
                    </LabeledList.Item>
                  </LabeledList>
                </Stack.Item>

                <Stack.Item>
                  <Box bold mb={1}>
                    Laws:
                  </Box>
                  <Box>
                    {laws.map((law, index) => (
                      <Box key={index} mb={0.5}>
                        {law.index}: {law.law}
                      </Box>
                    ))}
                  </Box>
                </Stack.Item>

                <Stack.Item>
                  <Box bold color={aiDead ? 'red' : 'green'}>
                    AI {aiDead ? 'nonfunctional' : 'functional'}
                  </Box>
                </Stack.Item>

                <Stack.Item>
                  {!active ? (
                    <Button
                      content="Begin Reconstruction"
                      onClick={() => act('fix')}
                      mt={2}
                    />
                  ) : (
                    <NoticeBox>
                      Reconstruction in process, please wait.
                    </NoticeBox>
                  )}
                </Stack.Item>
              </>
            ) : (
              <Stack.Item>
                <NoticeBox>No AI detected. Please insert an AI core.</NoticeBox>
              </Stack.Item>
            )}
          </Stack>
        </Section>
      </Window.Content>
    </Window>
  );
};
