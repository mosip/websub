package io.mosip.kafkaadminclient;

import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Properties;
import java.util.Set;
import org.apache.kafka.clients.admin.Admin;
import org.apache.kafka.clients.admin.AdminClientConfig;
import org.apache.kafka.clients.admin.CreateTopicsResult;
import org.apache.kafka.clients.admin.DescribeTopicsResult;
import org.apache.kafka.clients.admin.ListTopicsOptions;
import org.apache.kafka.clients.admin.NewTopic;
import org.apache.kafka.clients.admin.TopicDescription;
import org.apache.kafka.common.KafkaFuture;

public class MosipKafkaAdminClient {

	private Properties properties;

	public MosipKafkaAdminClient(String bootstrapServers) {
		properties = new Properties();
		properties.put(AdminClientConfig.BOOTSTRAP_SERVERS_CONFIG, bootstrapServers);

	}

	public void createTopic(String topicName) throws Exception {
		try (Admin admin = Admin.create(properties)) {
			NewTopic newTopic = new NewTopic(topicName, Optional.of(1), Optional.empty());
			CreateTopicsResult result = admin.createTopics(Collections.singleton(newTopic));
			// get the async result for the new topic creation
			KafkaFuture<Void> future = result.values().get(topicName);
			// call get() to block until topic creation has completed or failed
			future.get();
		}
	}

	public boolean isTopicsPresent(String topics) throws Exception {
		List<String> topicsList = Arrays.asList(topics.split(","));
		Set<String> kafkaTopics = getAllTopics();
		return topicsList.stream().allMatch(kafkaTopics::contains);
	}

	public Set<String> getAllTopics() throws Exception {
		try (Admin admin = Admin.create(properties)) {
			ListTopicsOptions listTopicsOptions = new ListTopicsOptions();
			listTopicsOptions.listInternal(true);
			return admin.listTopics(listTopicsOptions).names().get();
		}
	}

	public Map<String, TopicDescription> describeTopic(String topic) throws Exception {
		try (Admin admin = Admin.create(properties)) {
			DescribeTopicsResult result = admin.describeTopics(Collections.singleton(topic));
			return result.all().get();
		}
	}
}
