import React, { useEffect, useState } from 'react';
import { PieChart } from '@mui/x-charts/PieChart';
import { useDrawingArea } from '@mui/x-charts/hooks';
import { styled } from '@mui/material/styles';
import Typography from '@mui/material/Typography';
import Card from '@mui/material/Card';
import CardContent from '@mui/material/CardContent';
import Box from '@mui/material/Box';
import Stack from '@mui/material/Stack';
import LinearProgress, { linearProgressClasses } from '@mui/material/LinearProgress';
import Table from '@mui/material/Table';
import TableBody from '@mui/material/TableBody';
import TableCell from '@mui/material/TableCell';
import TableContainer from '@mui/material/TableContainer';
import TableHead from '@mui/material/TableHead';
import TableRow from '@mui/material/TableRow';
import Paper from '@mui/material/Paper';

const StyledText = styled('text')(({ theme }) => ({
  textAnchor: 'middle',
  dominantBaseline: 'central',
  fill: theme.palette.text.secondary,
  fontSize: theme.typography.body2.fontSize,
  fontWeight: theme.typography.body2.fontWeight,
}));

const PrimaryStyledText = styled(StyledText)(({ theme }) => ({
  fontSize: theme.typography.h5.fontSize,
  fontWeight: theme.typography.h5.fontWeight,
}));

function PieCenterLabel({ primaryText, secondaryText }) {
  const { width, height, left, top } = useDrawingArea();
  const primaryY = top + height / 2 - 10;
  const secondaryY = primaryY + 24;

  return (
    <>
      <PrimaryStyledText x={left + width / 2} y={primaryY}>
        {primaryText}
      </PrimaryStyledText>
      <StyledText x={left + width / 2} y={secondaryY}>
        {secondaryText}
      </StyledText>
    </>
  );
}

// More colourful palette (20 distinct colors)
const colors = [
  '#FF6384', '#36A2EB', '#FFCE56', '#4BC0C0', '#9966FF',
  '#FF9F40', '#E7E9ED', '#8BC34A', '#F44336', '#00BCD4',
  '#9C27B0', '#FFEB3B', '#795548', '#607D8B', '#E91E63',
  '#CDDC39', '#3F51B5', '#009688', '#FFC107', '#673AB7'
];

export default function ReactionsAnalytics() {
  const [reactionTypes, setReactionTypes] = useState([]);
  const [topEvents, setTopEvents] = useState([]);

  useEffect(() => {
    const token = sessionStorage.getItem('token');
    fetch('https://api.getyoa.app/yoaapi/analytics/reactions/reaction-types', {
      headers: { 'Content-Type': 'application/json','Authorization': `Bearer ${token}` }
    })
      .then(res => res.json())
      .then(data => setReactionTypes(Array.isArray(data) ? data.slice(0, 10) : []))
      .catch(() => setReactionTypes([]));

    fetch('https://api.getyoa.app/yoaapi/analytics/reactions/top-events', {
      headers: { 'Content-Type': 'application/json','Authorization': `Bearer ${token}` }
    })
      .then(res => res.json())
      .then(data => setTopEvents(Array.isArray(data) ? data.slice(0, 10) : []))
      .catch(() => setTopEvents([]));
  }, []);

  const totalReactions = reactionTypes.reduce((sum, type) => sum + type.count, 0);

  const pieChartData = reactionTypes.map((type, i) => ({
    label: type.reaction,
    value: type.count,
    color: colors[i % colors.length],
  }));

  const reactionTypesWithPercentage = reactionTypes.map((type, i) => ({
    ...type,
    percentage: totalReactions ? (type.count / totalReactions) * 100 : 0,
    color: colors[i % colors.length],
  }));

  return (
    <Card variant="outlined" sx={{ display: 'flex', flexDirection: 'column', gap: '16px', flexGrow: 1, p: 2 }}>
      <h2>
        <b>Reactions Analytics</b>
      </h2>
      <CardContent>
        <Typography component="h1" variant="h6" sx={{ mb: 2 }}>
          Top 10 Reaction Types
        </Typography>
        <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'center', mb: 3 }}>
          <PieChart
            series={[
              {
                data: pieChartData,
                innerRadius: 75,
                outerRadius: 100,
                paddingAngle: 2,
                highlightScope: { fade: 'global', highlight: 'item' },
                color: pieChartData.map(d => d.color),
              },
            ]}
            height={260}
            width={260}
            hideLegend
          >
            <PieCenterLabel primaryText={totalReactions.toString()} secondaryText="Total" />
          </PieChart>
        </Box>
        {reactionTypesWithPercentage.map((type, index) => (
          <Stack key={index} direction="row" sx={{ alignItems: 'center', gap: 2, pb: 2 }}>
            <Stack sx={{ gap: 1, flexGrow: 1 }}>
              <Stack direction="row" sx={{ justifyContent: 'space-between', alignItems: 'center', gap: 2 }}>
                <Typography variant="body2" sx={{ fontWeight: '500' }}>
                  {type.reaction}
                </Typography>
                <Typography variant="body2" sx={{ color: 'text.secondary' }}>
                  {type.percentage.toFixed(2)}%
                </Typography>
              </Stack>
              <LinearProgress
                variant="determinate"
                value={type.percentage}
                sx={{
                  [`& .${linearProgressClasses.bar}`]: {
                    backgroundColor: type.color,
                  },
                }}
              />
            </Stack>
          </Stack>
        ))}

        <Typography component="h2" variant="h6" sx={{ mt: 4, mb: 2 }}>
          Top 10 Events by Reactions
        </Typography>
        {topEvents.length === 0 ? (
          <Typography color="text.secondary">No data</Typography>
        ) : (
          <TableContainer component={Paper}>
            <Table size="small" aria-label="top events table">
              <TableHead>
                <TableRow>
                  <TableCell>Event Type</TableCell>
                  <TableCell>Creator</TableCell>
                  <TableCell align="right">Reactions</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {topEvents.map((ev) => (
                  <TableRow key={ev.event_idevent}>
                    <TableCell>{ev.event_name}</TableCell>
                    <TableCell>{ev.creator_name}</TableCell>
                    <TableCell align="right">{ev.reaction_count}</TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </TableContainer>
        )}
      </CardContent>
    </Card>
  );
}