import { sortBy } from 'common/collections';
import {
  Box,
  Button,
  ProgressBar,
  Section,
  Stack,
  Table,
  Tooltip,
} from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';

const JOB_REPORT_MENU_FAIL_REASON_TRACKING_DISABLED = 1;
const JOB_REPORT_MENU_FAIL_REASON_NO_RECORDS = 2;

const sortByPlaytime = (array: [string, number][]) =>
  sortBy(array, ([_, playtime]) => -playtime);

type PlaytimeSectionProps = {
  playtimes: Record<string, number>;
};

const PlaytimeSection: React.FC<PlaytimeSectionProps> = ({ playtimes }) => {
  const sortedPlaytimes = sortByPlaytime(Object.entries(playtimes)).filter(
    (entry) => entry[1],
  );

  if (!sortedPlaytimes.length) {
    return <>No recorded playtime hours for this section.</>;
  }

  const mostPlayed = sortedPlaytimes[0][1];
  return (
    <Table>
      {sortedPlaytimes.map(([jobName, playtime]) => {
        const ratio = playtime / mostPlayed;
        const totalMinutes = playtime;
        const totalHours = Math.floor(totalMinutes / 60);
        const days = Math.floor(totalHours / 24);
        const hours = totalHours % 24;
        const minutes = totalMinutes % 60;
        return (
          <Table.Row key={jobName}>
            <Table.Cell
              collapsing
              p={0.5}
              style={{
                verticalAlign: 'middle',
              }}
            >
              <Box align="right">{jobName}</Box>
            </Table.Cell>
            <Table.Cell>
              <ProgressBar maxValue={mostPlayed} value={playtime}>
                <Stack>
                  <Stack.Item width={`${ratio * 100}%`} />
                  <Tooltip content={totalHours >= 24 && `${totalHours} hours`}>
                    <Stack.Item
                      style={{
                        whiteSpace: 'nowrap',
                      }}
                    >
                      {days > 0 && `${days}d `}
                      {hours > 0 && `${hours}h `}
                      {minutes > 0 && `${minutes}m`}
                    </Stack.Item>
                  </Tooltip>
                </Stack>
              </ProgressBar>
            </Table.Cell>
          </Table.Row>
        );
      })}
    </Table>
  );
};

interface TrackedPlaytimeData {
  failReason: number | null;
  jobPlaytimes: Record<string, number>;
  specialPlaytimes: Record<string, number>;
  exemptStatus: boolean;
  isAdmin: boolean;
  livingTime: number;
  ghostTime: number;
  adminTime: number;
}

export const TrackedPlaytime = (props) => {
  const { act, data } = useBackend<TrackedPlaytimeData>();
  const {
    failReason,
    jobPlaytimes,
    specialPlaytimes,
    exemptStatus,
    isAdmin,
    livingTime,
    ghostTime,
    adminTime,
  } = data;
  return (
    <Window title="Tracked Playtime" width={550} height={650}>
      <Window.Content scrollable>
        {(failReason &&
          ((failReason === JOB_REPORT_MENU_FAIL_REASON_TRACKING_DISABLED && (
            <Box>This server has disabled tracking.</Box>
          )) ||
            (failReason === JOB_REPORT_MENU_FAIL_REASON_NO_RECORDS && (
              <Box>You have no records.</Box>
            )))) || (
          <Box>
            <Section
              title="Total"
              buttons={
                <Tooltip content="Hover over the playtime to get a pure hour count">
                  <Button icon="question" />
                </Tooltip>
              }
            >
              <PlaytimeSection
                playtimes={{
                  Ghost: ghostTime,
                  Living: livingTime,
                  Admin: adminTime,
                }}
              />
            </Section>
            <Section
              title="Jobs"
              buttons={
                !!isAdmin && (
                  <Button.Checkbox
                    checked={!!exemptStatus}
                    onClick={() => act('toggle_exempt')}
                  >
                    Job Playtime Exempt
                  </Button.Checkbox>
                )
              }
            >
              <PlaytimeSection playtimes={jobPlaytimes} />
            </Section>
            <Section title="Special">
              <PlaytimeSection playtimes={specialPlaytimes} />
            </Section>
          </Box>
        )}
      </Window.Content>
    </Window>
  );
};
